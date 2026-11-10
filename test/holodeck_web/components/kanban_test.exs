defmodule HolodeckWeb.Components.KanbanTest do
  use Holodeck.DataCase, async: false

  alias Hologram.{Component, Server}
  alias Holodeck.Kanban
  alias HolodeckWeb.Components.Kanban.{Board, Card, Column}

  defp card, do: %{id: "a", title: "Example", column: "todo", position: 1, version: 1}
  defp snapshot(revision \\ 1, cards \\ [card()]), do: %{revision: revision, cards: cards}

  defp component do
    %Component{
      state: %{
        confirmed: snapshot(),
        pending: nil,
        busy: nil,
        request_seq: 0,
        draft_title: "",
        error: "",
        status: "",
        reset_confirmation: nil
      }
    }
  end

  defp moving do
    Board.action(
      :request_move,
      %{card_id: "a", expected_version: 1, destination: "done"},
      component()
    )
  end

  defp settled(component, seq, snapshot, status \\ :ok) do
    Board.action(
      :move_settled,
      %{seq: seq, snapshot: snapshot, status: status, operation: :move_card},
      component
    )
  end

  test "only the board subscribes and mount queues a fresh snapshot" do
    {board, server} = Board.init(%{}, %Component{}, %Server{})
    assert board.state.confirmed == Kanban.snapshot()
    assert board.next_action.name == :sync
    assert length(server.subscriptions) == 1
    assert Board.action(:sync, %{}, board).next_command.name == :snapshot

    assert Board.command(:snapshot, %{}, %Server{}).next_action.params.snapshot ==
             Kanban.snapshot()
  end

  test "move targets the owning column, which forwards to the board" do
    card_component = %Component{
      props: %{card: card(), column_cid: "kanban-column-todo", disabled: false}
    }

    next = Card.action(:move, %{destination: "done"}, card_component).next_action
    assert next.target == "kanban-column-todo"
    assert next.name == :request_move
    forwarded = Column.action(next.name, next.params, %Component{}).next_action
    assert forwarded.target == "kanban-board"
    assert forwarded.params == %{card_id: "a", expected_version: 1, destination: "done"}
  end

  test "optimism never changes confirmed; only one mutation can be pending; Sync stays enabled" do
    moving = moving()
    assert moving.state.confirmed == snapshot()
    assert moving.state.pending.seq == 1
    assert moving.next_command.name == :move_card
    assert moving.next_action.name == :move_timeout
    assert moving.next_action.delay == 10_000
    assert hd(Board.display_cards(moving.state.confirmed, moving.state.pending)).column == "done"
    assert Board.action(:add_card, %{}, moving) == moving
    assert Board.action(:delete_card, %{}, moving) == moving
    assert Board.action(:request_move, %{card_id: "a", destination: "doing"}, moving) == moving
    assert Board.action(:sync, %{}, moving).next_command.name == :snapshot

    assert Board.action(:request_move, %{card_id: "a", destination: "todo"}, component()) ==
             component()
  end

  test "ignore older/equal snapshots and retain overlay for unchanged versions" do
    moving = moving()

    for snap <- [snapshot(0), snapshot(1, [])] do
      assert Board.action(:receive_snapshot, %{snapshot: snap}, moving) == moving
    end

    result = Board.action(:receive_snapshot, %{snapshot: snapshot(2)}, moving)
    assert result.state.confirmed.revision == 2
    assert result.state.pending == moving.state.pending
  end

  test "changed or deleted cards discard the overlay, including a broadcast before the reply" do
    for cards <- [[], [%{card() | version: 2, column: "doing"}]] do
      result = Board.action(:receive_snapshot, %{snapshot: snapshot(2, cards)}, moving())
      assert result.state.pending == nil

      assert result.state.error ==
               "This card changed in another browser. Showing the latest board."

      result = settled(result, 1, snapshot(2, cards), :conflict)
      assert result.state.busy == nil
      assert result.state.confirmed.cards == cards
      assert result.state.error =~ "another browser"
    end
  end

  test "matching success settles; late replies and timeouts cannot clear a newer move" do
    done = snapshot(2, [%{card() | column: "done", version: 2}])
    result = settled(moving(), 1, done)
    assert result.state.pending == nil
    assert result.state.busy == nil
    assert result.state.error == ""

    newer =
      Board.action(
        :request_move,
        %{card_id: "a", expected_version: 2, destination: "doing"},
        result
      )

    late = settled(newer, 1, done)
    assert late.state.pending == newer.state.pending
    assert late.state.busy == 2
    assert Board.action(:move_timeout, %{seq: 1}, newer) == newer
  end

  test "timeout clears and fetches without retry; late response can still advance confirmed" do
    result = Board.action(:move_timeout, %{seq: 1}, moving())
    assert result.state.pending == nil
    assert result.state.busy == nil
    assert result.state.error =~ "timed out"
    assert result.next_command.name == :snapshot
    late = settled(result, 1, snapshot(2))
    assert late.state.confirmed.revision == 2
    assert late.state.error =~ "timed out"
  end

  test "add/delete wait for confirmation, and reset captures the displayed revision" do
    initial = %{component() | state: Map.put(component().state, :draft_title, "New card")}
    add = Board.action(:add_card, %{}, initial)
    assert add.state.confirmed == initial.state.confirmed
    assert add.state.pending == nil
    assert add.next_command.params.title == "New card"
    assert Board.action(:reset_board, %{}, component()) == component()
    reset = Board.action(:confirm_reset, %{}, component())
    assert reset.state.reset_confirmation == 1
    reset = Board.action(:receive_snapshot, %{snapshot: snapshot(2)}, reset)
    assert Board.action(:reset_board, %{}, reset).next_command.params.expected_revision == 1

    c = %Component{props: %{card: card(), disabled: false}, state: %{delete_confirmation: false}}
    assert Card.action(:delete, %{}, c) == c
    confirmed = Card.action(:confirm_delete, %{}, c)
    assert Card.action(:delete, %{}, confirmed).next_action.target == "kanban-board"
    assert Card.action(:cancel_delete, %{}, confirmed).state.delete_confirmation == false
  end

  test "commands broadcast success and return full snapshots on conflicts" do
    card = hd(Kanban.snapshot().cards)
    params = %{card_id: card.id, expected_version: card.version, destination: "done", seq: 7}
    success = Board.command(:move_card, params, %Server{})
    assert success.next_action.params.seq == 7
    assert success.next_action.params.status == :ok
    assert length(success.broadcasts) == 1
    assert hd(success.broadcasts).channel == {:kanban, "public"}
    failure = Board.command(:move_card, %{params | expected_version: -1}, %Server{})
    assert failure.next_action.params.status == :conflict
    assert failure.broadcasts == []
    assert failure.next_action.params.snapshot == Kanban.snapshot()
  end
end
