defmodule HolodeckWeb.Dashboard.DashboardPageTest do
  use ExUnit.Case, async: true

  alias HolodeckWeb.Dashboard.DashboardPage
  alias Hologram.Component

  test "log stream retains only the newest 100 entries in newest-first order" do
    component =
      Enum.reduce(1..150, %Component{state: %{log_msgs: []}}, fn number, component ->
        DashboardPage.action(:logger, %{msg: Integer.to_string(number)}, component)
      end)

    assert Enum.map(component.state.log_msgs, & &1.msg) ==
             Enum.map(150..51//-1, &Integer.to_string/1)
  end
end
