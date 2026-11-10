defmodule Holodeck.PollsTest do
  use Holodeck.DataCase, async: true

  alias Holodeck.Polls

  describe "get_poll/1" do
    test "returns nil for an unknown UUID" do
      assert Polls.get_poll(Ecto.UUID.generate()) == nil
    end

    test "returns nil for a malformed ID" do
      assert Polls.get_poll("not-a-uuid") == nil
    end
  end
end
