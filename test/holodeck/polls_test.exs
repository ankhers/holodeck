defmodule Holodeck.PollsTest do
  use Holodeck.DataCase, async: true

  alias Holodeck.Polls

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
    test "returns an error for a missing poll" do
      assert {:error, %Ecto.Changeset{}} = Polls.vote(Ecto.UUID.generate(), 1)
    end

    test "returns an error for a malformed poll ID" do
      assert {:error, _reason} = Polls.vote("not-a-uuid", 1)
    end
  end
end
