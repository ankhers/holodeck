defmodule HolodeckWeb.Chat.RoomPageTest do
  use Holodeck.DataCase, async: true

  alias Hologram.Component
  alias Hologram.Server
  alias Holodeck.Chat
  alias HolodeckWeb.Chat.RoomPage

  test "a missing room renders without loading messages or subscribing" do
    {component, server} =
      RoomPage.init(%{room_name: "zz-agent-missing"}, %Component{}, %Server{})

    assert component.state.room == nil
    assert component.state.messages == []
    assert server.subscriptions == []
  end

  test "sending preserves the draft until the server confirms success" do
    component = %Component{state: %{username: "Alice", room: %{id: "room"}, draft: "Hello"}}
    result = RoomPage.action(:send_message, %{}, component)
    assert result.state.draft == "Hello"
  end

  test "failed sends show an error toast" do
    {:ok, room} = Chat.create_room("zz-agent-send-error", "Alice")

    server =
      RoomPage.command(:send_message, %{username: nil, room: room, message: "Hello"}, %Server{})

    assert server.next_action.name == :show
    assert server.next_action.target == "toast"
    assert server.next_action.params.variant == :error
    assert server.broadcasts == []
  end

  test "successful sends clear only the submitted draft" do
    {:ok, room} = Chat.create_room("zz-agent-send-success", "Alice")

    server =
      RoomPage.command(
        :send_message,
        %{username: "Alice", room: room, message: "Hello"},
        %Server{}
      )

    assert server.next_action.name == :message_sent
    assert length(server.broadcasts) == 1

    component = %Component{state: %{draft: "Hello"}}
    assert RoomPage.action(:message_sent, server.next_action.params, component).state.draft == ""

    component = %Component{state: %{draft: "A newer draft"}}

    assert RoomPage.action(:message_sent, server.next_action.params, component).state.draft ==
             "A newer draft"
  end

  test "an existing room loads its messages and subscribes" do
    {:ok, room} = Chat.create_room("zz-agent-existing", "Alice")
    {:ok, message} = Chat.create_message("Alice", room.id, "Hello")

    {component, server} =
      RoomPage.init(%{room_name: room.name}, %Component{}, %Server{})

    assert component.state.room == room
    assert component.state.messages == [message]
    assert {{:chat_room, room.name}, server.cid} in server.subscriptions
  end
end
