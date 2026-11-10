defmodule Holodeck.ChatTest do
  use Holodeck.DataCase, async: true

  alias Holodeck.Chat

  test "creating a duplicate room returns a friendly changeset error" do
    assert {:ok, room} = Chat.create_room("general", "Alice")
    assert {:error, changeset} = Chat.create_room(room.name, "Bob")
    assert errors_on(changeset).name == ["A room with this name already exists"]
    assert Chat.get_room_by_name(room.name).id == room.id
  end
end
