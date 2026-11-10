defmodule HolodeckWeb.Chat.RoomPageTest do
  use Holodeck.DataCase, async: true

  alias Hologram.Component
  alias Hologram.Server
  alias Holodeck.Chat
  alias HolodeckWeb.Chat.RoomPage

  test "message times show minutes in UTC and include the date on other days" do
    today = ~D[2026-05-30]
    assert RoomPage.message_time(~N[2026-05-30 09:02:13], today) == "09:02 UTC"

    assert RoomPage.message_time(~N[2026-05-29 14:32:59], today) ==
             "2026-05-29 · 14:32 UTC"

    assert RoomPage.message_time(~N[2025-01-01 00:00:00], today) ==
             "2025-01-01 · 00:00 UTC"
  end

  test "username colours use the whole name and support empty and Unicode names" do
    assert RoomPage.username_colour("Alice") != RoomPage.username_colour("Amy")
    assert RoomPage.username_colour("Alice") == RoomPage.username_colour("Alice")
    assert RoomPage.username_colour("Élodie") =~ ~r/^#[0-9a-f]{6}$/
    assert RoomPage.username_colour("") =~ ~r/^#[0-9a-f]{6}$/
  end

  test "a missing room renders without loading messages or subscribing" do
    {component, server} = RoomPage.init(%{room_name: "missing"}, %Component{}, %Server{})

    assert component.state.title == "Room not found · Holodeck"

    assert component.state.breadcrumbs == [
             {"Chat", HolodeckWeb.Chat.LobbyPage},
             {"Room not found", nil}
           ]

    assert component.state.room == nil
    assert component.state.messages == []
    assert component.state.username == ""
    assert server.subscriptions == []
  end

  test "sending clears the draft and queues only the room name and message" do
    {:ok, room} = Chat.create_room("general", "Alice")
    component = %Component{state: %{username: "Alice", room: room, draft: "Hello"}}

    result = RoomPage.action(:send_message, %{}, component)

    assert result.state.draft == ""
    assert result.next_command.name == :send_message
    assert result.next_command.params == %{room_name: room.name, message: "Hello"}

    # The runtime consumes the queued command before processing another action.
    result = %{result | next_command: nil}
    assert RoomPage.action(:send_message, %{}, result) == result
  end

  test "blank and whitespace-only drafts are ignored" do
    for draft <- ["", " ", "\t\n"] do
      component = %Component{state: %{draft: draft}}
      assert RoomPage.action(:send_message, %{}, component) == component
    end
  end

  test "commands use the session username and resolve the room server-side" do
    {:ok, room} = Chat.create_room("general", "Alice")
    {:ok, other_room} = Chat.create_room("other", "Bob")
    server = %Server{session: %{"holodeck_chat_username" => "Alice"}}

    result =
      RoomPage.command(
        :send_message,
        %{room_name: room.name, message: "Hello", username: "Mallory", room: other_room},
        server
      )

    assert [message] = Chat.get_messages_for_room(room)
    assert message.username == "Alice"
    assert message.message == "Hello"
    assert Chat.get_messages_for_room(other_room) == []
    assert result.next_action == nil
    assert length(result.broadcasts) == 1
    assert hd(result.broadcasts).channel == {:chat_room, room.name}
  end

  test "missing or blank session usernames queue send_failed instead of trusting params" do
    {:ok, room} = Chat.create_room("general", "Alice")

    for session <- [%{}, %{"holodeck_chat_username" => " "}] do
      result =
        RoomPage.command(
          :send_message,
          %{room_name: room.name, message: "Hello", username: "Mallory", room: room},
          %Server{session: session}
        )

      assert result.next_action.name == :send_failed
      assert result.next_action.params.text == "Hello"
      assert result.next_action.params.message =~ "username"
      assert result.broadcasts == []
    end

    assert Chat.get_messages_for_room(room) == []
  end

  test "a missing server-side room queues send_failed" do
    {:ok, room} = Chat.create_room("general", "Alice")

    result =
      RoomPage.command(
        :send_message,
        %{room_name: "missing", room: room, message: "Hello"},
        %Server{session: %{"holodeck_chat_username" => "Alice"}}
      )

    assert result.next_action.name == :send_failed
    assert result.next_action.params.text == "Hello"
    assert result.next_action.params.message == "Room not found"
    assert result.broadcasts == []
    assert Chat.get_messages_for_room(room) == []
  end

  test "validation failures queue send_failed with the changeset error" do
    {:ok, room} = Chat.create_room("general", "Alice")

    result =
      RoomPage.command(
        :send_message,
        %{room_name: room.name, message: " "},
        %Server{session: %{"holodeck_chat_username" => "Alice"}}
      )

    assert result.next_action.name == :send_failed
    assert result.next_action.params.text == " "
    assert result.next_action.params.message == "can't be blank"
    assert result.broadcasts == []
  end

  test "send_failed restores an empty draft and shows an error toast" do
    params = %{text: "Hello", message: "Room not found"}
    component = %Component{state: %{draft: ""}}
    result = RoomPage.action(:send_failed, params, component)

    assert result.state.draft == "Hello"
    assert result.next_action.name == :show
    assert result.next_action.target == "toast"
    assert result.next_action.params == %{message: "Room not found", variant: :error}
  end

  test "send_failed does not overwrite a newer draft" do
    component = %Component{state: %{draft: "A newer draft"}}
    result = RoomPage.action(:send_failed, %{text: "Hello", message: "Error"}, component)

    assert result.state.draft == "A newer draft"
    assert result.next_action.name == :show
  end

  test "an existing room loads its messages and subscribes" do
    {:ok, room} = Chat.create_room("general", "Alice")
    {:ok, message} = Chat.create_message("Alice", room.id, "Hello")

    {component, server} = RoomPage.init(%{room_name: room.name}, %Component{}, %Server{})

    assert component.state.title == "# general · Holodeck"

    assert component.state.breadcrumbs == [
             {"Chat", HolodeckWeb.Chat.LobbyPage},
             {"# general", nil}
           ]

    assert component.state.room == room
    assert component.state.messages == [message]
    name = room.name
    assert Enum.any?(server.subscriptions, &match?({{:chat_room, ^name}, _}, &1))
  end
end
