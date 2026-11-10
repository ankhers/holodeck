defmodule Holodeck.PollsTest do
  use Holodeck.DataCase, async: false

  alias Holodeck.Polls

  @valid_poll %{
    question: "Favourite colour?",
    answer_1: "Red",
    answer_2: "Blue",
    answer_3: "Green",
    answer_4: "Yellow"
  }

  describe "create_poll/1 validation" do
    for field <- [:question, :answer_1, :answer_2, :answer_3, :answer_4] do
      test "requires #{field}" do
        field = unquote(field)
        assert {:error, changeset} = Polls.create_poll(Map.delete(@valid_poll, field))
        assert errors_on(changeset) == %{field => ["can't be blank"]}
      end
    end
  end

  describe "recent_polls/0" do
    test "includes zero-vote polls and counts all answers without loading them" do
      Holodeck.HologramHelpers.ensure_pubsub_started()
      {:ok, empty} = Polls.create_poll(@valid_poll)
      {:ok, voted} = Polls.create_poll(@valid_poll)
      {:ok, _} = Polls.vote(voted.id, 1)
      {:ok, _} = Polls.vote(voted.id, 2)

      entries = Map.new(Polls.recent_polls(), &{&1.poll.id, &1.vote_count})
      assert entries == %{empty.id => 0, voted.id => 2}
    end

    test "returns only the latest ten polls, newest first" do
      polls =
        for n <- 1..12 do
          {:ok, poll} = Polls.create_poll(@valid_poll)
          inserted_at = NaiveDateTime.add(~N[2026-01-01 00:00:00], n)

          Repo.update_all(
            from(p in Holodeck.Polls.Poll, where: p.id == ^poll.id),
            set: [inserted_at: inserted_at]
          )

          poll.id
        end

      assert Enum.map(Polls.recent_polls(), & &1.poll.id) ==
               polls |> Enum.reverse() |> Enum.take(10)
    end
  end

  describe "get_poll/1" do
    test "returns an existing poll" do
      {:ok, poll} =
        Polls.create_poll(%{
          question: "zz-agent-favourite colour?",
          answer_1: "Red",
          answer_2: "Blue",
          answer_3: "Green",
          answer_4: "Yellow"
        })

      assert Polls.get_poll(poll.id) == poll
    end

    test "returns nil for an unknown UUID" do
      assert Polls.get_poll(Ecto.UUID.generate()) == nil
    end

    test "returns nil for a malformed ID" do
      assert Polls.get_poll("not-a-uuid") == nil
    end
  end

  describe "vote/2" do
    test "persists each valid answer" do
      Holodeck.HologramHelpers.ensure_pubsub_started()
      {:ok, poll} = Polls.create_poll(@valid_poll)

      votes =
        for answer <- 1..4 do
          assert {:ok, vote} = Polls.vote(poll.id, answer)
          assert vote.poll_id == poll.id
          assert vote.answer_number == answer
          vote
        end

      assert Enum.sort_by(Polls.get_answers_for(poll.id), & &1.answer_number) == votes
    end

    test "rejects answers outside the range without persisting a vote" do
      {:ok, poll} = Polls.create_poll(@valid_poll)

      assert {:error, below_range} = Polls.vote(poll.id, 0)
      assert errors_on(below_range).answer_number == ["must be greater than or equal to 1"]

      assert {:error, above_range} = Polls.vote(poll.id, 5)
      assert errors_on(above_range).answer_number == ["must be less than or equal to 4"]
      assert Polls.get_answers_for(poll.id) == []
    end

    test "returns an error for a missing poll" do
      assert {:error, %Ecto.Changeset{}} = Polls.vote(Ecto.UUID.generate(), 1)
    end

    test "returns an error for a malformed poll ID" do
      assert {:error, _reason} = Polls.vote("not-a-uuid", 1)
    end
  end
end
