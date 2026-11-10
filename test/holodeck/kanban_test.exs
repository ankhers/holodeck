defmodule Holodeck.KanbanTest do
  use ExUnit.Case, async: false
  alias Ecto.Adapters.SQL.Sandbox
  alias Holodeck.Kanban
  alias Holodeck.Kanban.{Board, Card}
  alias Holodeck.Repo

  setup do
    clean()
    on_exit(&clean/0)
    :ok
  end

  defp db(fun), do: Sandbox.unboxed_run(Repo, fun)

  defp clean do
    db(fn ->
      Repo.delete_all(Card)
      Repo.update_all(Board, set: [last_reset_at: nil])

      {:ok, _} =
        Kanban.reset_board(%{confirmed: true, expected_revision: Kanban.snapshot().revision})

      Repo.update_all(Board, set: [last_reset_at: nil])
    end)
  end

  defp race(funs) do
    parent = self()

    tasks =
      Enum.map(funs, fn fun ->
        Task.async(fn ->
          db(fn ->
            # Each worker has checked out its own real (non-sandboxed) connection.
            send(parent, {:ready, self()})

            receive do
              :go -> fun.()
            end
          end)
        end)
      end)

    pids =
      Enum.map(tasks, fn _ ->
        assert_receive {:ready, pid}
        pid
      end)

    Enum.each(pids, &send(&1, :go))
    Task.await_many(tasks)
  end

  defp move(card, destination),
    do: %{card_id: card.id, expected_version: card.version, destination: destination}

  test "validation, trimmed titles, untrusted params and full snapshots" do
    db(fn ->
      initial = Kanban.snapshot()
      assert length(initial.cards) == 6

      for params <- [
            nil,
            %{},
            %{title: " "},
            %{title: 12},
            %{title: String.duplicate("a", 121)},
            %{title: String.duplicate("e\u0301", 61)}
          ] do
        assert {:error, :invalid_title, ^initial} = Kanban.add_card(params)
      end

      assert {:error, :invalid_column, ^initial} = Kanban.add_card(%{title: "a", column: "bad"})
      assert {:ok, snapshot} = Kanban.add_card(%{"title" => "  hello  ", "column" => "done"})
      assert List.last(snapshot.cards).title == "hello"
      assert snapshot.revision == initial.revision + 1
      assert {:error, :conflict, ^snapshot} = Kanban.move_card(%{card_id: "bad"})
      assert {:error, :conflict, ^snapshot} = Kanban.delete_card(nil)
      card = hd(snapshot.cards)
      assert {:error, :invalid_column, ^snapshot} = Kanban.move_card(move(card, "bad"))
    end)
  end

  test "same-column is a no-op; moves append and increment version" do
    db(fn ->
      initial = Kanban.snapshot()
      card = hd(initial.cards)
      assert {:ok, ^initial} = Kanban.move_card(move(card, card.column))
      assert {:ok, next} = Kanban.move_card(move(card, "done"))
      moved = List.last(next.cards)
      assert moved.id == card.id
      assert moved.version == card.version + 1
      assert moved.position > List.last(initial.cards).position
      assert {:error, :conflict, ^next} = Kanban.move_card(move(card, "doing"))
      assert {:error, :conflict, ^next} = Kanban.delete_card(move(card, "done"))
      assert {:ok, deleted} = Kanban.delete_card(move(moved, "done"))
      refute Enum.any?(deleted.cards, &(&1.id == card.id))
    end)
  end

  test "cap holds under concurrent adds" do
    db(fn -> for n <- 1..23, do: Kanban.add_card(%{title: "Card #{n}"}) end)
    results = race(for n <- 1..4, do: fn -> Kanban.add_card(%{title: "Concurrent #{n}"}) end)
    assert Enum.count(results, &match?({:ok, _}, &1)) == 1
    assert Enum.count(results, &match?({:error, :cap, _}, &1)) == 3
    assert db(fn -> length(Kanban.snapshot().cards) end) == 30
  end

  test "concurrent moves from one version have exactly one winner" do
    card = db(fn -> hd(Kanban.snapshot().cards) end)
    results = race(for dest <- ~w(doing done), do: fn -> Kanban.move_card(move(card, dest)) end)
    assert Enum.count(results, &match?({:ok, _}, &1)) == 1
    assert Enum.count(results, &match?({:error, :conflict, _}, &1)) == 1
  end

  test "delete versus move has one winner" do
    card = db(fn -> hd(Kanban.snapshot().cards) end)

    results =
      race([
        fn -> Kanban.delete_card(move(card, "done")) end,
        fn -> Kanban.move_card(move(card, "done")) end
      ])

    assert Enum.count(results, &match?({:ok, _}, &1)) == 1
    assert Enum.count(results, &match?({:error, :conflict, _}, &1)) == 1
  end

  test "reset versus move has one winner and reset never reuses uuids" do
    initial = db(&Kanban.snapshot/0)
    card = hd(initial.cards)

    results =
      race([
        fn -> Kanban.reset_board(%{confirmed: true, expected_revision: initial.revision}) end,
        fn -> Kanban.move_card(move(card, "done")) end
      ])

    assert Enum.count(results, &match?({:ok, _}, &1)) == 1
    assert Enum.count(results, &match?({:error, :conflict, _}, &1)) == 1

    db(fn ->
      current = Kanban.snapshot()

      if Enum.any?(current.cards, &(&1.id == card.id)) do
        assert {:ok, reset} =
                 Kanban.reset_board(%{confirmed: true, expected_revision: current.revision})

        refute Enum.any?(reset.cards, &(&1.id in Enum.map(initial.cards, fn c -> c.id end)))
      end
    end)
  end

  test "reset requires confirmation, expected revision and global cooldown" do
    db(fn ->
      initial = Kanban.snapshot()
      assert {:error, :confirmation_required, ^initial} = Kanban.reset_board(%{})

      assert {:error, :conflict, ^initial} =
               Kanban.reset_board(%{confirmed: true, expected_revision: -1})

      assert {:ok, reset} =
               Kanban.reset_board(%{confirmed: true, expected_revision: initial.revision})

      assert reset.revision == initial.revision + 1

      assert {:error, :cooldown, ^reset} =
               Kanban.reset_board(%{confirmed: true, expected_revision: reset.revision})

      Repo.update_all(Board, set: [last_reset_at: DateTime.add(DateTime.utc_now(), -60, :second)])
      assert {:ok, _} = Kanban.reset_board(%{confirmed: true, expected_revision: reset.revision})
    end)
  end
end
