defmodule HolodeckWeb.ChatBrowserTest do
  use ExUnit.Case, async: false
  use Wallaby.Feature

  import Holodeck.BrowserHelpers

  alias HolodeckWeb.Chat.{LobbyPage, RoomPage}

  @moduletag :e2e

  setup tags do
    Holodeck.DataCase.setup_sandbox(tags)
    {:ok, room} = Holodeck.Chat.create_room("browser-chat", "Alice")
    %{room: room}
  end

  @sessions 2
  feature "a message reaches another browser already in the room", %{
    sessions: [sender, reader],
    room: room
  } do
    sender
    |> visit_page(LobbyPage)
    |> fill_in(Query.css("#chat-username"), with: "Alice")
    |> click(Query.css("#save-username"))
    |> assert_has(Query.css("#current-username", text: "Alice"))

    sender = visit_page(sender, RoomPage, room_name: room.name)
    reader = visit_page(reader, RoomPage, room_name: room.name)

    reader
    |> assert_has(Query.css("#username-required"))
    |> refute_has(Query.css("#messages", text: "Hello from another browser!"))

    sender
    |> fill_in(Query.css("#chat-message"), with: "Hello from another browser!")
    |> click(Query.css("#send-message"))
    |> assert_has(Query.css("#messages", text: "Hello from another browser!"))

    reader
    |> assert_has(Query.css("#messages", text: "Hello from another browser!"))
    |> assert_has(Query.css("#messages", text: "Alice"))
  end
end
