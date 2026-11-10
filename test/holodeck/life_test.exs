defmodule Holodeck.LifeTest do
  use ExUnit.Case, async: true

  alias Holodeck.Life

  defp next(cells) do
    {next_cells, population} = Life.next(cells)
    assert population == Life.population(next_cells)
    next_cells
  end

  defp board(points) do
    Enum.reduce(points, Life.empty(), fn {x, y}, cells -> put_elem(cells, y * 24 + x, 1) end)
  end

  test "empty world stays empty" do
    assert next(Life.empty()) == Life.empty()
  end

  test "birth and survival depend on the eight neighbours" do
    neighbours = for y <- 10..12, x <- 10..12, {x, y} != {11, 11}, do: {x, y}

    for count <- 0..8, alive <- [0, 1] do
      points = Enum.take(neighbours, count)
      points = if alive == 1, do: [{11, 11} | points], else: points
      expected = if count == 3 or (alive == 1 and count == 2), do: 1, else: 0
      assert elem(next(board(points)), 11 * 24 + 11) == expected
    end
  end

  test "block is a still life" do
    cells = board([{10, 10}, {11, 10}, {10, 11}, {11, 11}])
    assert next(cells) == cells
  end

  test "blinker has period two" do
    cells = Life.preset(:blinker)
    assert next(cells) != cells
    assert next(next(cells)) == cells
  end

  test "glider translates one cell diagonally every four generations" do
    cells = Life.preset(:glider)
    translated = for id <- 0..575, elem(cells, id) == 1, do: {rem(id, 24) + 1, div(id, 24) + 1}
    assert Enum.reduce(1..4, cells, fn _, acc -> next(acc) end) == board(translated)
  end

  test "edges are dead, not wrapped, and do not join adjacent rows" do
    assert next(board([{23, 10}, {0, 11}, {1, 11}])) == Life.empty()
    assert next(board([{23, 23}, {0, 0}, {1, 0}])) == Life.empty()
    assert next(board([{0, 0}, {1, 0}, {0, 1}])) == board([{0, 0}, {1, 0}, {0, 1}, {1, 1}])
  end

  test "presets fit the finite board with the expected populations" do
    for {name, count} <- [glider: 5, blinker: 3, pulsar: 48] do
      cells = Life.preset(name)
      assert tuple_size(cells) == 576
      assert Life.population(cells) == count
      assert Enum.all?(Tuple.to_list(cells), &(&1 in [0, 1]))

      assert Enum.all?(0..575, fn id ->
               elem(cells, id) == 0 or (rem(id, 24) in 1..22 and div(id, 24) in 1..22)
             end)
    end

    pulsar = Life.preset(:pulsar)
    assert Enum.reduce(1..3, pulsar, fn _, acc -> next(acc) end) == pulsar
  end

  test "random boards contain only binary cells" do
    cells = Life.random()
    assert tuple_size(cells) == 576
    assert Enum.all?(Tuple.to_list(cells), &(&1 in [0, 1]))
    assert Life.population(cells) == Enum.count(Tuple.to_list(cells), &(&1 == 1))
  end
end
