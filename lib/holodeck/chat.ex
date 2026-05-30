defmodule Holodeck.Chat do
  alias Holodeck.Chat.Message
  alias Holodeck.Chat.Room
  alias Holodeck.Repo

  import Ecto.Query

  def list_rooms do
    Repo.all(from r in Room, order_by: r.name)
  end

  def create_room(room_name, username) do
    %Room{}
    |> Room.create_changeset(%{name: room_name, creator: username})
    |> Repo.insert()
  end

  def get_room_by_name(name) do
    Repo.one(from r in Room, where: r.name == ^name)
  end

  def create_message(username, room_id, message) do
    %Message{}
    |> Message.create_changeset(%{username: username, room_id: room_id, message: message})
    |> Repo.insert()
  end

  def get_messages_for_room(room) do
    Repo.all(from m in Message, where: m.room_id == ^room.id, order_by: {:desc, m.inserted_at})
    |> dbg()
  end
end
