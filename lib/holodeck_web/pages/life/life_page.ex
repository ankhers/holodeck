defmodule HolodeckWeb.Life.LifePage do
  use HolodeckWeb, :page

  alias Holodeck.Life

  route "/life"
  layout HolodeckWeb.Layout, title: "Game of Life · Holodeck"

  def init(_params, component, _server) do
    cells = Life.preset(:glider)

    put_state(component,
      cells: cells,
      running: false,
      loop_token: 0,
      delay_ms: 200,
      generation: 0,
      population: Life.population(cells)
    )
  end

  def action(:play, _params, %{state: %{running: false}} = component) do
    token = component.state.loop_token + 1

    component
    |> put_state(running: true, loop_token: token)
    |> schedule_tick(token)
  end

  def action(:play, _params, component), do: component

  def action(:pause, _params, component) do
    put_state(component, running: false, loop_token: component.state.loop_token + 1)
  end

  def action(:tick, %{token: token}, component) do
    if component.state.running and token == component.state.loop_token do
      component |> advance() |> schedule_tick(token)
    else
      component
    end
  end

  def action(:step, _params, component) do
    if component.state.running, do: component, else: advance(component)
  end

  def action(:clear, _params, component), do: reset(component, Life.empty())
  def action(:randomise, _params, component), do: reset(component, Life.random())

  def action(:preset, %{name: name}, component) when name in [:glider, :blinker, :pulsar],
    do: reset(component, Life.preset(name))

  def action(:toggle, %{id: id}, component) when is_integer(id) and id >= 0 and id < 576 do
    cells = component.state.cells
    value = 1 - elem(cells, id)

    put_state(component,
      cells: put_elem(cells, id, value),
      population: component.state.population + value - elem(cells, id)
    )
  end

  def action(:speed, %{event: %{value: value}}, component) do
    case value do
      "100" -> change_speed(component, 100)
      "200" -> change_speed(component, 200)
      "500" -> change_speed(component, 500)
      "1000" -> change_speed(component, 1000)
      _ -> component
    end
  end

  defp change_speed(component, delay) do
    token = component.state.loop_token + 1
    component = put_state(component, delay_ms: delay, loop_token: token)
    if component.state.running, do: schedule_tick(component, token), else: component
  end

  defp advance(component) do
    cells = Life.next(component.state.cells)

    put_state(component,
      cells: cells,
      population: Life.population(cells),
      generation: component.state.generation + 1
    )
  end

  defp reset(component, cells) do
    component
    |> action_pause()
    |> put_state(cells: cells, population: Life.population(cells), generation: 0)
  end

  defp action_pause(component), do: action(:pause, %{}, component)

  defp schedule_tick(component, token) do
    put_action(component,
      name: :tick,
      delay: component.state.delay_ms,
      params: %{token: token}
    )
  end
end
