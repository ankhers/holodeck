defmodule HolodeckWeb.Components.ToastTest do
  use ExUnit.Case, async: true

  alias Hologram.{Component, Server}
  alias HolodeckWeb.Components.Toast

  test "show schedules auto-dismiss and hide preserves the message" do
    {component, _server} = Toast.init(%{}, %Component{}, %Server{})
    refute component.state.visible

    shown = Toast.action(:show, %{message: "Try again", variant: :error}, component)
    assert shown.state.visible
    assert shown.state.message == "Try again"
    assert shown.state.variant == :error
    assert shown.next_action.name == :hide
    assert shown.next_action.delay == 4000

    hidden = Toast.action(:hide, %{}, shown)
    refute hidden.state.visible
    assert hidden.state.message == "Try again"
  end
end
