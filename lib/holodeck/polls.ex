defmodule Holodeck.Polls do
  alias Holodeck.Polls.Poll
  alias Holodeck.Polls.Result
  alias Holodeck.Repo

  import Ecto.Query

  @doc "Channel for changes to the recent polls list: new polls and vote counts."
  def recent_channel, do: {:polls, "recent"}

  def create_poll(params) do
    %Poll{}
    |> Poll.create_changeset(params)
    |> Repo.insert()
  end

  @doc "Returns the ten newest polls and their vote counts in a single query."
  def recent_polls do
    Repo.all(
      from p in Poll,
        left_join: r in Result,
        on: r.poll_id == p.id,
        group_by: p.id,
        order_by: [desc: p.inserted_at, desc: p.id],
        limit: 10,
        select: %{poll: p, vote_count: count(r.id)}
    )
  end

  def get_poll(poll_id) do
    case Ecto.UUID.cast(poll_id) do
      {:ok, uuid} -> Repo.get(Poll, uuid)
      :error -> nil
    end
  end

  def get_answers_for(poll_id) do
    Repo.all(from r in Result, where: r.poll_id == ^poll_id)
  end

  def vote(poll_id, answer_number) do
    with {:ok, uuid} <- Ecto.UUID.cast(poll_id) do
      result =
        %Result{poll_id: uuid}
        |> Result.create_changeset(%{answer_number: answer_number})
        |> Repo.insert()

      with {:ok, r} <- result do
        Hologram.Realtime.broadcast_action({:poll_result, uuid}, :update_results, result: r)
        Hologram.Realtime.broadcast_action(recent_channel(), :vote_recorded, poll_id: uuid)
        result
      end
    else
      :error -> {:error, :invalid_poll_id}
    end
  end
end
