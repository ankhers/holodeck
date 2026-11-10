defmodule Holodeck.Life do
  @moduledoc "Finite 24×24 Conway's Game of Life, using a flat tuple of dead/live cells."
  @size 24
  @offsets for dy <- -1..1, dx <- -1..1, {dx, dy} != {0, 0}, do: {dx, dy}

  def empty, do: List.to_tuple(List.duplicate(0, @size * @size))

  def random do
    1..(@size * @size)
    |> Enum.map(fn _ -> if :rand.uniform() < 0.25, do: 1, else: 0 end)
    |> List.to_tuple()
  end

  def population(cells), do: cells |> Tuple.to_list() |> Enum.sum()

  def next(cells) do
    0..(@size * @size - 1)
    |> Enum.map(fn id ->
      x = rem(id, @size)
      y = div(id, @size)

      neighbours =
        Enum.reduce(@offsets, 0, fn {dx, dy}, count ->
          count + cell(cells, x + dx, y + dy)
        end)

      if neighbours == 3 or (elem(cells, id) == 1 and neighbours == 2), do: 1, else: 0
    end)
    |> List.to_tuple()
  end

  def preset(:glider), do: place([{1, 0}, {2, 1}, {0, 2}, {1, 2}, {2, 2}], 10, 10)
  def preset(:blinker), do: place([{0, 0}, {1, 0}, {2, 0}], 10, 11)

  def preset(:pulsar) do
    arm = [2, 3, 4, 8, 9, 10]
    bars = [0, 5, 7, 12]
    points = for a <- arm, b <- bars, point <- [{a, b}, {b, a}], do: point
    place(points, 5, 5)
  end

  defp place(points, ox, oy) do
    Enum.reduce(points, empty(), fn {x, y}, cells ->
      put_elem(cells, (y + oy) * @size + x + ox, 1)
    end)
  end

  defp cell(_cells, x, y) when x < 0 or x >= @size or y < 0 or y >= @size, do: 0
  defp cell(cells, x, y), do: elem(cells, y * @size + x)
end
