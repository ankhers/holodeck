defmodule Holodeck.ChatTest do
  use Holodeck.DataCase, async: true

  alias Holodeck.Chat
  alias Holodeck.Repo

  test "list_rooms returns rooms in name order" do
    {:ok, zulu} = Chat.create_room("zulu", "Alice")
    {:ok, alpha} = Chat.create_room("alpha", "Bob")
    {:ok, middle} = Chat.create_room("middle", "Carol")

    assert Chat.list_rooms() == [alpha, middle, zulu]
  end

  describe "create_room/2 validation" do
    test "rejects a blank name" do
      assert {:error, changeset} = Chat.create_room("   ", "Alice")
      assert errors_on(changeset).name == ["Room name can't be blank"]
    end

    test "rejects a name shorter than three characters" do
      assert {:error, changeset} = Chat.create_room("ab", "Alice")
      assert errors_on(changeset).name == ["should be at least 3 character(s)"]
    end

    test "requires a creator" do
      assert {:error, changeset} = Chat.create_room("general", nil)
      assert errors_on(changeset).creator == ["Username can't be blank"]
    end
  end

  describe "create_message/3" do
    setup do
      {:ok, room} = Chat.create_room("general", "Alice")
      %{room: room}
    end

    test "persists a valid message", %{room: room} do
      assert {:ok, message} = Chat.create_message("Alice", room.id, "Hello!")
      assert message.username == "Alice"
      assert message.room_id == room.id
      assert message.message == "Hello!"
      assert Chat.get_messages_for_room(room) == [message]
    end

    test "requires a username", %{room: room} do
      assert {:error, changeset} = Chat.create_message(" ", room.id, "Hello!")
      assert errors_on(changeset).username == ["can't be blank"]
    end

    test "requires message text", %{room: room} do
      assert {:error, changeset} = Chat.create_message("Alice", room.id, " ")
      assert errors_on(changeset).message == ["can't be blank"]
    end

    test "rejects an unknown room" do
      assert {:error, changeset} = Chat.create_message("Alice", Ecto.UUID.generate(), "Hello!")
      assert errors_on(changeset).room == ["does not exist"]
    end

    test "requires a room" do
      assert {:error, changeset} = Chat.create_message("Alice", nil, "Hello!")
      assert errors_on(changeset).room_id == ["can't be blank"]
    end
  end

  test "get_messages_for_room returns only that room's messages, newest first" do
    {:ok, room} = Chat.create_room("general", "Alice")
    {:ok, other_room} = Chat.create_room("other", "Bob")
    # Insert newest first so the assertion distinguishes timestamp order from insertion order.
    {:ok, newest} = Chat.create_message("Alice", room.id, "Newest")
    {:ok, oldest} = Chat.create_message("Alice", room.id, "Oldest")
    {:ok, _other} = Chat.create_message("Bob", other_room.id, "Elsewhere")

    # Explicit timestamps avoid relying on insert order or the wall clock's resolution.
    oldest =
      oldest
      |> Ecto.Changeset.change(inserted_at: ~N[2025-01-01 00:00:00])
      |> Repo.update!()

    newest =
      newest
      |> Ecto.Changeset.change(inserted_at: ~N[2025-01-02 00:00:00])
      |> Repo.update!()

    assert Chat.get_messages_for_room(room) == [newest, oldest]
  end

  test "creating a duplicate room returns a friendly changeset error" do
    assert {:ok, room} = Chat.create_room("general", "Alice")
    assert {:error, changeset} = Chat.create_room(room.name, "Bob")
    assert errors_on(changeset).name == ["A room with this name already exists"]
    assert Chat.get_room_by_name(room.name).id == room.id
  end
end
