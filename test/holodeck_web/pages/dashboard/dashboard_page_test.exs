defmodule HolodeckWeb.Dashboard.DashboardPageTest do
  use ExUnit.Case, async: true

  alias HolodeckWeb.Dashboard.DashboardPage
  alias Hologram.Component
  alias Hologram.Server

  test "sort action uses its parameter for each supported column" do
    for by <- [:memory, :reductions, :pid] do
      result = DashboardPage.action(:sort, %{by: by}, %Component{})
      assert result.state.process_sort == by
      assert result.next_command.name == :process_sort
      assert result.next_command.params == %{by: by}
    end
  end

  test "sort command persists supported columns and returns sorted metrics" do
    for {saved, by} <- sort_values() do
      result = DashboardPage.command(:process_sort, %{by: saved}, %Server{})
      assert result.session["holodeck_dashboard_process_sort"] == by
      assert result.next_action.name == :store_metrics
      assert_sorted(result.next_action.params, by)

      tick = DashboardPage.command(:tick, %{seq: 1}, result)
      assert_sorted(tick.next_action.params.metrics, by)
    end
  end

  test "invalid or missing sort parameters do not change state or reach metrics" do
    for params <- [%{by: :unsupported}, %{by: "unknown"}, %{}, %{order: :memory}] do
      component = %Component{state: %{process_sort: :memory}}
      server = %Server{}
      assert DashboardPage.action(:sort, params, component) == component
      assert DashboardPage.command(:process_sort, params, server) == server
    end
  end

  test "init normalizes atom, string and unknown session sorts" do
    for {saved, by} <- sort_values() ++ [{"unknown", :memory}, {nil, :memory}, {%{}, :memory}] do
      server = %Server{session: %{"holodeck_dashboard_process_sort" => saved}}
      {component, _server} = DashboardPage.init(%{}, %Component{}, server)
      assert component.state.process_sort == by
      assert_sorted(component.state.system_metrics, by)
      assert component.next_action.name == :start_monitoring
    end
  end

  test "tick normalizes atom, string and unknown session sorts" do
    for {saved, by} <- sort_values() ++ [{"unknown", :memory}, {nil, :memory}, {%{}, :memory}] do
      server = %Server{session: %{"holodeck_dashboard_process_sort" => saved}}
      result = DashboardPage.command(:tick, %{seq: 7}, server)
      assert result.next_action.name == :tick_update
      assert result.next_action.params.seq == 7
      assert_sorted(result.next_action.params.metrics, by)
    end
  end

  test "monitoring initializes its timestamps in the client action, not during SSR" do
    before = System.monotonic_time(:millisecond)
    result = DashboardPage.action(:start_monitoring, %{}, %Component{state: %{tick_seq: 0}})
    assert result.state.last_tick_at >= before
    assert result.state.last_tick_request_at >= result.state.last_tick_at
    assert result.next_command.name == :tick
    assert result.state.tick_seq == 1
    assert result.next_command.params == %{seq: 1}
    assert result.next_action.name == :watchdog
    assert result.next_action.delay == 1_000
  end

  test "watchdog marks missed updates stale, retries, and independently reschedules itself" do
    now = System.monotonic_time(:millisecond)

    result =
      DashboardPage.action(:watchdog, %{}, %Component{
        state: %{last_tick_at: now - 16_000, last_tick_request_at: now - 6_000, tick_seq: 1}
      })

    assert result.state.metrics_status == :stale
    assert result.next_command.name == :tick
    assert result.state.last_tick_request_at >= now
    assert result.state.tick_seq == 2
    assert result.next_command.params == %{seq: 2}
    assert result.next_action.name == :watchdog
    assert result.next_action.delay == 1_000

    waiting = DashboardPage.action(:watchdog, %{}, %{result | next_command: nil})
    assert waiting.next_command == nil
    assert waiting.next_action.name == :watchdog
  end

  test "a successful update restores live status and normal tick scheduling" do
    before = System.monotonic_time(:millisecond)

    result =
      DashboardPage.action(:tick_update, %{seq: 1, metrics: %{sample: :fresh}}, %Component{
        state: %{metrics_status: :stale, tick_seq: 1}
      })

    assert result.state.metrics_status == :live
    assert result.state.last_tick_at >= before
    assert result.state.system_metrics == %{sample: :fresh}
    assert result.next_action.name == :tick
    assert result.next_action.delay == 5_000

    watching = DashboardPage.action(:watchdog, %{}, result)
    assert watching.state.metrics_status == :live
    assert watching.next_command == nil
    assert watching.next_action.name == :watchdog
  end

  test "slow and retried responses refresh metrics but schedule exactly one next tick" do
    first = DashboardPage.action(:tick, %{}, %Component{state: %{tick_seq: 0}})
    retry = DashboardPage.action(:tick, %{}, %{first | next_command: nil})
    assert first.next_command.params.seq == 1
    assert retry.next_command.params.seq == 2

    for responses <- [[1, 2], [2, 1]] do
      {_, scheduled} =
        Enum.reduce(responses, {%{retry | next_command: nil}, []}, fn seq,
                                                                      {component, scheduled} ->
          # The runtime consumes next_action before dispatching the following response.
          component = %{component | next_action: nil}
          params = %{seq: seq, metrics: %{sample: seq}}
          result = DashboardPage.action(:tick_update, params, component)
          assert result.state.system_metrics == params.metrics
          assert result.state.metrics_status == :live
          assert result.state.tick_seq == 2

          if seq == 1 do
            assert result.next_action == nil
          else
            assert result.next_action.name == :tick
            assert result.next_action.delay == 5_000
          end

          {result, [result.next_action | scheduled]}
        end)

      assert Enum.count(scheduled, &(&1 != nil)) == 1
    end
  end

  test "freshness boundary uses three missed five-second intervals" do
    assert DashboardPage.metrics_status(15_000, 0) == :live
    assert DashboardPage.metrics_status(15_001, 0) == :stale
    assert DashboardPage.metrics_dot_class(:stale) == "hd-live-dot hd-live-dot-stale"
    assert DashboardPage.log_status_label(:live) == "streaming"
    assert DashboardPage.log_status_label(:stale) == "reconnecting…"
  end

  test "bars and log levels use theme colours" do
    assert DashboardPage.bar_class(85.0) == "bg-error"
    assert DashboardPage.bar_class(60) == "bg-warning"
    assert DashboardPage.bar_class(12.5) == "bg-info"
    assert DashboardPage.log_level_class(%{level: :critical}) =~ "text-error"
    assert DashboardPage.log_level_class(%{level: :warning}) =~ "text-warning"
    assert DashboardPage.log_level_class(%{level: :info}) =~ "text-info"
  end

  defp sort_values do
    [
      {:memory, :memory},
      {"memory", :memory},
      {:reductions, :reductions},
      {"reductions", :reductions},
      {:pid, :pid},
      {"pid", :pid}
    ]
  end

  defp assert_sorted(metrics, by) do
    processes = metrics.processes
    assert length(processes) == 20

    values =
      Enum.map(processes, fn {pid, info} ->
        if by == :pid, do: pid, else: Keyword.fetch!(info, by)
      end)

    direction = if by == :pid, do: :asc, else: :desc
    assert values == Enum.sort(values, direction)
  end

  test "log timestamps are formatted as UTC" do
    timestamp = DateTime.to_unix(~U[2026-04-01 23:04:05Z], :microsecond)
    assert DashboardPage.format_time(timestamp) == "23:04:05"
  end

  test "log stream retains only the newest 100 entries in newest-first order" do
    component =
      Enum.reduce(1..150, %Component{state: %{log_msgs: []}}, fn number, component ->
        DashboardPage.action(:logger, %{msg: Integer.to_string(number)}, component)
      end)

    assert Enum.map(component.state.log_msgs, & &1.msg) ==
             Enum.map(150..51//-1, &Integer.to_string/1)
  end
end
