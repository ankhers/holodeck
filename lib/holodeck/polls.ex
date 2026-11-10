defmodule Holodeck.Polls do
  alias Holodeck.Polls.Poll
  alias Holodeck.Polls.Result
  alias Holodeck.Repo

  import Ecto.Query

  def create_poll(params) do
    %Poll{}
    |> Poll.create_changeset(params)
    |> Repo.insert()
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
    result =
      %Result{poll_id: poll_id}
      |> Result.create_changeset(%{answer_number: answer_number})
      |> Repo.insert()

    with {:ok, r} <- result do
      Hologram.Realtime.broadcast_action({:poll_result, poll_id}, :update_results, result: r)
      result
    end
  end
end
