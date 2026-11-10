defmodule HolodeckWeb.Dashboard.DashboardPage do
  use HolodeckWeb, :page

  alias Holodeck.Dashboard

  route "/dashboard"

  layout HolodeckWeb.Layout, title: "Dashboard · Holodeck"

  @tick_delay 5_000
  @log_limit 100

  def init(_params, component, server) do
    process_sort = saved_sort(server)

    system_metrics = Dashboard.system_metrics(process_sort: process_sort)

    component =
      component
      |> put_state(
        system_metrics: system_metrics,
        process_sort: process_sort,
        log_msgs: [],
        metrics_status: :live,
        last_tick_at: nil,
        last_tick_request_at: nil,
        tick_seq: 0
      )
      |> put_action(:start_monitoring)

    server = put_subscription(server, {:dashboard, "logs"})

    {component, server}
  end

  def action(:logger, params, component) do
    put_state(component, log_msgs: Enum.take([params | component.state.log_msgs], @log_limit))
  end

  def action(:sort, %{by: by}, component) when by in [:memory, :reductions, :pid] do
    component
    |> put_command(:process_sort, %{by: by})
    |> put_state(process_sort: by)
  end

  def action(:sort, _params, component), do: component

  def action(:start_monitoring, _params, component) do
    now = System.monotonic_time(:millisecond)

    component = put_state(component, last_tick_at: now)

    action(:tick, %{}, component)
    |> put_action(name: :watchdog, delay: 1_000)
  end

  # An independent action timer can detect (and retry) a failed command round-trip.
  def action(:watchdog, _params, component) do
    now = System.monotonic_time(:millisecond)
    status = metrics_status(now, component.state.last_tick_at)

    component =
      component
      |> put_state(metrics_status: status)
      |> put_action(name: :watchdog, delay: 1_000)

    if status == :stale and now - component.state.last_tick_request_at >= @tick_delay do
      action(:tick, %{}, component)
    else
      component
    end
  end

  def action(:tick, _params, component) do
    seq = component.state.tick_seq + 1

    component
    |> put_state(tick_seq: seq, last_tick_request_at: System.monotonic_time(:millisecond))
    |> put_command(:tick, %{seq: seq})
  end

  def action(:tick_update, %{seq: seq, metrics: metrics}, component) do
    component =
      put_state(component,
        system_metrics: metrics,
        last_tick_at: System.monotonic_time(:millisecond),
        metrics_status: :live
      )

    # Superseded responses may refresh metrics, but only the latest request continues the loop.
    if seq == component.state.tick_seq do
      put_action(component, name: :tick, delay: @tick_delay)
    else
      component
    end
  end

  def action(:store_metrics, system_metrics, component) do
    put_state(component, system_metrics: system_metrics)
  end

  def command(:process_sort, %{by: by}, server)
      when by in [:memory, :reductions, :pid, "memory", "reductions", "pid"] do
    by = normalize_sort(by)
    system_metrics = Dashboard.system_metrics(process_sort: by)

    server
    |> put_session("holodeck_dashboard_process_sort", by)
    |> put_action(:store_metrics, system_metrics)
  end

  def command(:process_sort, _params, server), do: server

  def command(:tick, %{seq: seq}, server) do
    process_sort = saved_sort(server)

    system_metrics = Dashboard.system_metrics(process_sort: process_sort)

    put_action(server, :tick_update, %{seq: seq, metrics: system_metrics})
  end

  def normalize_sort(value) when value in [:memory, "memory"], do: :memory
  def normalize_sort(value) when value in [:reductions, "reductions"], do: :reductions
  def normalize_sort(value) when value in [:pid, "pid"], do: :pid
  def normalize_sort(_value), do: :memory

  defp saved_sort(server) do
    server |> get_session("holodeck_dashboard_process_sort", :memory) |> normalize_sort()
  end

  def metrics_status(now, last_tick_at) when now - last_tick_at > 15_000, do: :stale
  def metrics_status(_now, _last_tick_at), do: :live

  def metrics_status_class(:live), do: "text-success"
  def metrics_status_class(:stale), do: "text-warning"

  def metrics_dot_class(:live), do: "hd-live-dot"
  def metrics_dot_class(:stale), do: "hd-live-dot hd-live-dot-stale"

  # The log stream shares the tick connection, so the tick freshness doubles as its status.
  def log_status_label(:live), do: "streaming"
  def log_status_label(:stale), do: "reconnecting…"

  def bar_class(percent) when percent >= 80, do: "bg-error"
  def bar_class(percent) when percent >= 60, do: "bg-warning"
  def bar_class(_percent), do: "bg-info"

  def format_percent(f), do: :erlang.float_to_binary(f / 1, decimals: 2)

  def format_bytes(bytes) when bytes >= 1_099_511_627_776,
    do: "#{Float.round(bytes / 1_099_511_627_776, 1)} TB"

  def format_bytes(bytes) when bytes >= 1_073_741_824,
    do: "#{Float.round(bytes / 1_073_741_824, 1)} GB"

  def format_bytes(bytes) when bytes >= 1_048_576,
    do: "#{Float.round(bytes / 1_048_576, 1)} MB"

  def format_bytes(bytes) when bytes >= 1_024,
    do: "#{Float.round(bytes / 1_024, 1)} KB"

  def format_bytes(bytes),
    do: "#{bytes} B"

  def format_uptime(ms) do
    total_seconds = div(ms, 1000)
    days = div(total_seconds, 86400)
    hours = div(rem(total_seconds, 86400), 3600)
    minutes = div(rem(total_seconds, 3600), 60)

    cond do
      days > 0 -> "#{days}d #{hours}h"
      hours > 0 -> "#{hours}h #{minutes}m"
      true -> "#{minutes}m"
    end
  end

  def format_integer(n) when is_integer(n) do
    n
    |> Integer.to_string()
    |> String.graphemes()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.join(",")
    |> String.reverse()
  end

  def sort_button_class(a, a), do: "hd-sort-btn-active"
  def sort_button_class(_a, _b), do: "hd-sort-btn"

  def log_level(%{level: level}), do: level |> Atom.to_string() |> String.upcase()

  def format_time(timestamp),
    do: timestamp |> DateTime.from_unix!(:microsecond) |> Calendar.strftime("%H:%M:%S")

  def log_level_class(%{level: :warning}), do: "bg-warning/10 text-warning"

  def log_level_class(%{level: level}) when level in [:error, :critical, :alert, :emergency],
    do: "bg-error/10 text-error"

  def log_level_class(%{level: :debug}), do: "bg-base-content/10 text-base-content/60"
  def log_level_class(_log), do: "bg-info/10 text-info"
end
