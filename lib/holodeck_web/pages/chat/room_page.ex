defmodule HolodeckWeb.Chat.RoomPage do
  use HolodeckWeb, :page

  alias Holodeck.Chat
  alias HolodeckWeb.ChangesetErrors

  route "/chat/:room_name"
  param :room_name, :string

  layout HolodeckWeb.Layout, title: "Chat room · Holodeck"

  def init(params, component, server) do
    username = get_session(server, "holodeck_chat_username", "")
    room = Chat.get_room_by_name(params.room_name)
    messages = if room, do: Chat.get_messages_for_room(room), else: []

    component =
      put_state(component,
        messages: messages,
        room: room,
        username: username,
        draft: "",
        title: if(room, do: "# #{room.name} · Holodeck", else: "Room not found · Holodeck")
      )

    server = if room, do: put_subscription(server, {:chat_room, room.name}), else: server

    {component, server}
  end

  def action(:update_draft, params, component) do
    put_state(component, :draft, params.event.value)
  end

  def action(:send_message, _params, component) do
    if String.trim(component.state.draft) == "" do
      component
    else
      component
      |> put_command(:send_message, %{
        room_name: component.state.room.name,
        message: component.state.draft
      })
      |> put_state(:draft, "")
    end
  end

  def action(:send_failed, params, component) do
    component =
      if component.state.draft == "" do
        put_state(component, :draft, params.text)
      else
        component
      end

    put_action(component,
      name: :show,
      target: "toast",
      params: %{message: params.message, variant: :error}
    )
  end

  def action(:add_message, params, component) do
    put_state(component, :messages, [params.message | component.state.messages])
  end

  def command(:send_message, params, server) do
    # Resolve identity and room on the server; command params are client-controlled.
    username = get_session(server, "holodeck_chat_username", "")
    room = Chat.get_room_by_name(params.room_name)

    cond do
      !is_binary(username) || String.trim(username) == "" ->
        send_failed(server, params.message, "Set a username in the lobby to send messages.")

      is_nil(room) ->
        send_failed(server, params.message, "Room not found")

      true ->
        case Chat.create_message(username, room.id, params.message) do
          {:ok, message} ->
            put_broadcast(server, {:chat_room, room.name}, :add_message, message: message)

          {:error, changeset} ->
            send_failed(server, params.message, ChangesetErrors.message(changeset))
        end
    end
  end

  defp send_failed(server, text, message) do
    put_action(server, :send_failed, text: text, message: message)
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
