defmodule HolodeckWeb.Chat.LobbyPage do
  use HolodeckWeb, :page

  alias Holodeck.Chat

  alias HolodeckWeb.Chat.RoomPage
  alias HolodeckWeb.ChangesetErrors

  route "/chat"

  layout HolodeckWeb.Layout, title: "Chat · Holodeck"

  def init(_params, component, server) do
    rooms = Chat.list_rooms()

    username = get_session(server, "holodeck_chat_username", "")

    # Every lobby hears about new rooms, so the list stays current without a reload.
    {put_state(component, rooms: rooms, username: username),
     put_subscription(server, {:chat, "rooms"})}
  end

  def action(:create_room, params, component) do
    put_command(component, :create_room, room_name: params.event["room_name"])
  end

  def action(:room_created, params, component) do
    put_page(component, RoomPage, room_name: params.room.name)
  end

  def action(:room_added, params, component) do
    rooms =
      [params.room | Enum.reject(component.state.rooms, &(&1.id == params.room.id))]
      |> Enum.sort_by(& &1.name)

    put_state(component, :rooms, rooms)
  end

  def action(:save_username, params, component) do
    put_command(component, :save_username, username: params.event["username"])
  end

  def action(:username_saved, params, component) do
    component
    |> put_state(:username, params.username)
    |> put_action(
      name: :show,
      target: "toast",
      params: %{message: "Username saved", variant: :success}
    )
  end

  def command(:create_room, params, server) do
    username = get_session(server, "holodeck_chat_username")

    case Chat.create_room(params.room_name, username) do
      {:ok, room} ->
        server
        |> put_broadcast({:chat, "rooms"}, :room_added, room: room)
        |> put_action(:room_created, room: room)

      {:error, changeset} ->
        put_action(server,
          name: :show,
          target: "toast",
          params: %{message: ChangesetErrors.message(changeset), variant: :error}
        )
    end
  end

  def command(:save_username, params, server) do
    changeset =
      {%{}, %{username: :string}}
      |> Ecto.Changeset.cast(%{username: params.username}, [:username])
      |> Ecto.Changeset.update_change(:username, &String.trim/1)
      |> Ecto.Changeset.validate_required(:username, message: "Username can't be blank")
      |> Ecto.Changeset.validate_length(:username,
        max: 32,
        count: :codepoints,
        message: "Usernames can be at most 32 characters"
      )

    if changeset.valid? do
      username = Ecto.Changeset.get_field(changeset, :username)

      server
      |> put_session("holodeck_chat_username", username)
      |> put_action(:username_saved, username: username)
    else
      put_action(server,
        name: :show,
        target: "toast",
        params: %{message: ChangesetErrors.message(changeset), variant: :error}
      )
    end
  end
end
