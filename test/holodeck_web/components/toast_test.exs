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
    assert shown.next_action.params == %{generation: 1}

    hidden = Toast.action(:hide, shown.next_action.params, shown)
    refute hidden.state.visible
    assert hidden.state.message == "Try again"
  end

  test "an older timer cannot dismiss a toast shown after manual dismissal" do
    {component, _server} = Toast.init(%{}, %Component{}, %Server{})
    first = Toast.action(:show, %{message: "First", variant: :info}, component)
    dismissed = Toast.action(:hide, %{}, first)
    refute dismissed.state.visible

    second = Toast.action(:show, %{message: "Second", variant: :error}, dismissed)
    assert second.state.generation == 2
    assert Toast.action(:hide, first.next_action.params, second) == second
    refute Toast.action(:hide, second.next_action.params, second).state.visible
  end

  test "an older timer cannot dismiss a replacement toast" do
    {component, _server} = Toast.init(%{}, %Component{}, %Server{})
    first = Toast.action(:show, %{message: "First", variant: :info}, component)
    second = Toast.action(:show, %{message: "Second", variant: :success}, first)

    assert Toast.action(:hide, first.next_action.params, second) == second
    refute Toast.action(:hide, second.next_action.params, second).state.visible
  end
end
