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
    for by <- [:memory, :reductions, :pid] do
      result = DashboardPage.command(:process_sort, %{by: by}, %Server{})
      assert result.session["holodeck_dashboard_process_sort"] == by
      assert result.next_action.name == :store_metrics
      assert length(result.next_action.params.processes) == 20
    end
  end

  test "invalid or missing sort parameters do not change state or reach metrics" do
    for params <- [%{by: :unsupported}, %{by: "memory"}, %{}, %{order: :memory}] do
      component = %Component{state: %{process_sort: :memory}}
      server = %Server{}
      assert DashboardPage.action(:sort, params, component) == component
      assert DashboardPage.command(:process_sort, params, server) == server
    end
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
