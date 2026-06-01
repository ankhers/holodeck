defmodule HolodeckWeb.Chat.LobbyPage do
  use HolodeckWeb, :page

  alias Holodeck.Chat

  alias HolodeckWeb.Chat.RoomPage

  route "/chat"

  layout HolodeckWeb.Chat.Layout

  def init(_params, component, server) do
    rooms = Chat.list_rooms()

    username = get_session(server, "holodeck_chat_username", "")

    put_state(component, rooms: rooms, username: username)
  end

  def action(:create_room, params, component) do
    put_command(component, :create_room, room_name: params.event["room_name"])
  end

  def action(:room_created, params, component) do
    put_page(component, RoomPage, room_name: params.room.name)
  end

  def action(:save_username, params, component) do
    component
    |> put_command(:save_username, username: params.event["username"])
    |> put_state(username: params.event["username"])
  end

  def command(:create_room, params, server) do
    username = get_session(server, "holodeck_chat_username")

    case Chat.create_room(params.room_name, username) do
      {:ok, room} ->
        put_action(server, :room_created, room: room)

      {:error, reason} ->
        # TODO: Show a toast of the reason
        server
    end
  end

  def command(:save_username, params, server) do
    put_session(server, "holodeck_chat_username", params.username)
  end
end
