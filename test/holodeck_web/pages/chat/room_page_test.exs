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
