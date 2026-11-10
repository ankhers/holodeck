defmodule HolodeckWeb.Chat.RoomPage do
  use HolodeckWeb, :page

  alias Holodeck.Chat

  route "/chat/:room_name"
  param :room_name, :string

  layout HolodeckWeb.Chat.Layout

  def init(params, component, server) do
    username = get_session(server, "holodeck_chat_username")
    room = Chat.get_room_by_name(params.room_name)
    messages = if room, do: Chat.get_messages_for_room(room), else: []

    component =
      put_state(component, messages: messages, room: room, username: username, draft: "")

    server = if room, do: put_subscription(server, {:chat_room, room.name}), else: server

    {component, server}
  end

  def action(:update_draft, params, component) do
    put_state(component, :draft, params.event.value)
  end

  def action(:send_message, _params, component) do
    username = component.state.username
    room = component.state.room

    put_command(component, :send_message, %{
      username: username,
      room: room,
      message: component.state.draft
    })
  end

  def action(:message_sent, params, component) do
    if component.state.draft == params.message do
      put_state(component, :draft, "")
    else
      component
    end
  end

  def action(:add_message, params, component) do
    put_state(component, :messages, [params.message | component.state.messages])
  end

  def command(:send_message, params, server) do
    case Holodeck.Chat.create_message(params.username, params.room.id, params.message) do
      {:ok, message} ->
        server
        |> put_broadcast({:chat_room, params.room.name}, :add_message, message: message)
        |> put_action(:message_sent, message: params.message)

      {:error, _changeset} ->
        put_action(server,
          name: :show,
          target: "toast",
          params: %{
            message:
              "Message could not be sent. Set a username in the lobby and enter a message.",
            variant: :error
          }
        )
    end
  end

  @colours [
    "#a78bfa",
    "#f472b6",
    "#34d399",
    "#60a5fa",
    "#fbbf24",
    "#f87171",
    "#a3e635",
    "#38bdf8",
    "#c084fc",
    "#fb923c"
  ]
  @colours_length length(@colours)

  def username_colour(<<first, _::binary>>) do
    index = rem(first, @colours_length)
    Enum.at(@colours, index)
  end
end
