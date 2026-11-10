defmodule HolodeckWeb.Life.LifePageTest do
  use ExUnit.Case, async: true

  alias Holodeck.Life
  alias HolodeckWeb.Life.LifePage
  alias Hologram.Component

  defp initial do
    component = LifePage.init(%{}, %Component{}, %Hologram.Server{})
    assert component.next_command == nil
    assert component.next_action == nil
    component
  end

  # The dispatcher consumes effects between callbacks. Model that here so a
  # previous next_action cannot be mistaken for a newly scheduled timer.
  defp act(component, name, params \\ %{}) do
    result = LifePage.action(name, params, %{component | next_action: nil})
    assert result.next_command == nil
    assert result.state.population == Life.population(result.state.cells)
    result
  end

  test "starts paused with a centred glider" do
    component = initial()
    assert component.state.cells == Life.preset(:glider)
    assert component.state.generation == 0
    refute component.state.running
  end

  test "play twice schedules only one loop" do
    playing = act(initial(), :play)
    assert playing.next_action.name == :tick
    assert playing.next_action.delay == 200
    assert playing.next_action.params == %{token: playing.state.loop_token}
    again = act(playing, :play)
    assert again.next_action == nil
    assert again.state.loop_token == playing.state.loop_token
    ticked = act(again, :tick, playing.next_action.params)
    assert ticked.state.generation == 1
    assert ticked.next_action.params == playing.next_action.params
    assert ticked.next_action.delay == 200
    assert ticked.state.cells == Life.next(playing.state.cells)
  end

  test "pause/play rejects the old tick" do
    playing = act(initial(), :play)
    paused = act(playing, :pause)
    rejected = act(paused, :tick, playing.next_action.params)
    assert rejected.state == paused.state
    assert rejected.next_action == nil
    resumed = act(rejected, :play)
    stale = act(resumed, :tick, playing.next_action.params)
    assert stale.state == resumed.state
    assert stale.next_action == nil
    assert act(stale, :tick, resumed.next_action.params).state.generation == 1
  end

  test "speed changes validate, invalidate old ticks and schedule one replacement" do
    playing = act(initial(), :play)
    changed = act(playing, :speed, %{event: %{value: "100"}})
    assert changed.next_action.name == :tick
    assert changed.next_action.delay == 100
    assert changed.next_action.params == %{token: changed.state.loop_token}
    assert changed.state.loop_token == playing.state.loop_token + 1
    stale = act(changed, :tick, playing.next_action.params)
    assert stale.state.generation == 0
    assert stale.next_action == nil
    assert act(stale, :tick, changed.next_action.params).state.generation == 1

    for value <- ["200", "500", "1000"] do
      updated = act(initial(), :speed, %{event: %{value: value}})
      assert updated.state.delay_ms == String.to_integer(value)
      assert updated.state.loop_token == 1
      refute updated.state.running
      assert updated.next_action == nil
    end

    invalid = act(changed, :speed, %{event: %{value: "1"}})
    assert invalid.state == changed.state
    assert invalid.next_action == nil
  end

  test "step advances exactly once while paused and is ignored while running" do
    paused = initial()
    stepped = act(paused, :step)
    assert stepped.state.cells == Life.next(paused.state.cells)
    assert stepped.state.generation == 1
    assert stepped.next_action == nil
    playing = act(stepped, :play)
    assert act(playing, :step).state == playing.state
  end

  test "clear, randomise and every preset pause, reset and invalidate timers" do
    for {action, params} <- [
          {:clear, %{}},
          {:randomise, %{}},
          {:preset, %{name: :glider}},
          {:preset, %{name: :blinker}},
          {:preset, %{name: :pulsar}}
        ] do
      playing = initial() |> act(:step) |> act(:play)
      reset = act(playing, action, params)
      refute reset.state.running
      assert reset.state.generation == 0
      assert reset.state.loop_token == playing.state.loop_token + 1
      assert reset.next_action == nil
      assert act(reset, :tick, playing.next_action.params).state == reset.state
      resumed = act(reset, :play)
      assert act(resumed, :tick, playing.next_action.params).state == resumed.state

      case action do
        :clear -> assert reset.state.population == 0
        :preset -> assert reset.state.cells == Life.preset(params.name)
        :randomise -> assert tuple_size(reset.state.cells) == 576
      end
    end
  end

  test "cells toggle while paused without advancing or starting a timer" do
    paused = initial()

    for id <- [0, 575] do
      toggled = act(paused, :toggle, %{id: id})
      assert elem(toggled.state.cells, id) == 1
      assert toggled.state.population == paused.state.population + 1
      assert toggled.state.generation == 0
      assert toggled.state.loop_token == paused.state.loop_token
      refute toggled.state.running
      assert toggled.next_action == nil
      assert act(toggled, :toggle, %{id: id}).state == paused.state
    end
  end

  test "cells toggle while playing without interrupting the loop" do
    playing = act(initial(), :play)
    toggled = act(playing, :toggle, %{id: 0})
    assert elem(toggled.state.cells, 0) == 1
    assert toggled.state.running
    assert toggled.state.loop_token == playing.state.loop_token
    assert act(toggled, :toggle, %{id: 0}).state.cells == playing.state.cells
    live_id = Enum.find(0..575, &(elem(playing.state.cells, &1) == 1))
    removed = act(playing, :toggle, %{id: live_id})
    assert elem(removed.state.cells, live_id) == 0
    assert removed.state.population == playing.state.population - 1
    assert removed.next_action == nil
  end
end
