defmodule Holodeck.Kanban do
  @moduledoc "One public board. The board row serializes all writes, including cap and version checks."
  import Ecto.Query
  alias Holodeck.Kanban.{Board, Card}
  alias Holodeck.Repo

  @columns ~w(todo doing done)
  @examples [
    {"Explore Hologram", "todo"},
    {"Try a targeted action", "todo"},
    {"Move a card", "doing"},
    {"Open another browser", "doing"},
    {"Build something together", "done"},
    {"Celebrate the small wins", "done"}
  ]

  def snapshot do
    # Locking also keeps the revision and cards from different writes out of one snapshot.
    {:ok, snapshot} = Repo.transaction(fn -> locked_board() |> snapshot_for() end)
    snapshot
  end

  def add_card(params) do
    mutate(fn board ->
      title = value(params, :title)
      column = value(params, :column) || "todo"
      title = if is_binary(title), do: String.trim(title), else: ""

      cond do
        length(String.to_charlist(title)) not in 1..120 ->
          {:error, :invalid_title}

        column not in @columns ->
          {:error, :invalid_column}

        Repo.aggregate(Card, :count) >= 30 ->
          {:error, :cap}

        true ->
          Repo.insert!(%Card{
            board_id: "public",
            title: title,
            column: column,
            position: board.next_position
          })

          {:changed, %{next_position: board.next_position + 1}}
      end
    end)
  end

  def move_card(params) do
    mutate(fn board ->
      with {:ok, card} <- current_card(params),
           destination when destination in @columns <- value(params, :destination) do
        if destination == card.column do
          :unchanged
        else
          card
          |> Ecto.Changeset.change(
            column: destination,
            version: card.version + 1,
            position: board.next_position
          )
          |> Repo.update!()

          {:changed, %{next_position: board.next_position + 1}}
        end
      else
        {:error, reason} -> {:error, reason}
        _ -> {:error, :invalid_column}
      end
    end)
  end

  def delete_card(params) do
    mutate(fn _board ->
      with {:ok, card} <- current_card(params) do
        Repo.delete!(card)
        {:changed, %{}}
      end
    end)
  end

  def reset_board(params) do
    mutate(fn board ->
      now = DateTime.utc_now()

      cond do
        value(params, :confirmed) != true ->
          {:error, :confirmation_required}

        value(params, :expected_revision) != board.revision ->
          {:error, :conflict}

        board.last_reset_at && DateTime.diff(now, board.last_reset_at, :second) < 60 ->
          {:error, :cooldown}

        true ->
          Repo.delete_all(Card)

          Enum.with_index(@examples, board.next_position)
          |> Enum.each(fn {{title, column}, position} ->
            Repo.insert!(%Card{
              board_id: "public",
              title: title,
              column: column,
              position: position
            })
          end)

          {:changed, %{next_position: board.next_position + 6, last_reset_at: now}}
      end
    end)
  end

  defp mutate(fun) do
    {:ok, result} =
      Repo.transaction(fn ->
        board = locked_board()

        case fun.(board) do
          {:error, reason} ->
            {:error, reason, snapshot_for(board)}

          :unchanged ->
            {:ok, snapshot_for(board)}

          {:changed, changes} ->
            board =
              board
              |> Ecto.Changeset.change(Map.put(changes, :revision, board.revision + 1))
              |> Repo.update!()

            {:ok, snapshot_for(board)}
        end
      end)

    result
  end

  defp locked_board, do: Repo.one!(from b in Board, where: b.id == "public", lock: "FOR UPDATE")

  defp snapshot_for(board) do
    cards =
      Repo.all(
        from c in Card,
          where: c.board_id == "public",
          order_by: [asc: c.position, asc: c.id],
          select: map(c, [:id, :title, :column, :position, :version])
      )

    %{revision: board.revision, cards: cards}
  end

  defp current_card(params) do
    with {:ok, id} <- Ecto.UUID.cast(value(params, :card_id)),
         %Card{} = card <- Repo.get(Card, id),
         true <-
           is_integer(value(params, :expected_version)) and
             card.version == value(params, :expected_version) do
      {:ok, card}
    else
      _ -> {:error, :conflict}
    end
  end

  defp value(params, key) when is_map(params),
    do: Map.get(params, key, Map.get(params, Atom.to_string(key)))

  defp value(_params, _key), do: nil
end
