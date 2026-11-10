defmodule HolodeckWeb.Chat.LobbyPageTest do
  use Holodeck.DataCase, async: true

  alias Hologram.Component
  alias Hologram.Server
  alias HolodeckWeb.Chat.LobbyPage

  test "the lobby loads the session username" do
    component =
      LobbyPage.init(%{}, %Component{}, %Server{
        session: %{"holodeck_chat_username" => "Alice"}
      })

    assert component.state.username == "Alice"
  end

  test "saving a username trims and persists it before updating the display" do
    result = LobbyPage.command(:save_username, %{username: "  Alice  "}, %Server{})

    assert Server.get_session(result, "holodeck_chat_username") == "Alice"
    assert result.next_action.name == :username_saved
    assert result.next_action.params == %{username: "Alice"}

    component = LobbyPage.action(:username_saved, result.next_action.params, %Component{})
    assert component.state.username == "Alice"
    assert component.next_action.name == :show
    assert component.next_action.target == "toast"
    assert component.next_action.params == %{message: "Username saved", variant: :success}
  end

  test "invalid usernames leave the session unchanged and show an error toast" do
    server = %Server{session: %{"holodeck_chat_username" => "Alice"}}

    for username <- ["", "  ", String.duplicate("a", 300), String.duplicate("👨‍👩‍👧", 32)] do
      result = LobbyPage.command(:save_username, %{username: username}, server)

      assert Server.get_session(result, "holodeck_chat_username") == "Alice"
      assert result.next_action.name == :show
      assert result.next_action.target == "toast"
      assert result.next_action.params.variant == :error
    end
  end

  test "the displayed username does not optimistically adopt an invalid save" do
    component = %Component{state: %{username: "Alice"}}
    result = LobbyPage.action(:save_username, %{event: %{"username" => " "}}, component)
    assert result.state.username == "Alice"
    assert result.next_command.name == :save_username
  end

  test "32-codepoint usernames are accepted" do
    username = String.duplicate("a", 32)
    result = LobbyPage.command(:save_username, %{username: username}, %Server{})
    assert Server.get_session(result, "holodeck_chat_username") == username
  end

  test "legacy oversized session usernames fail safely when creating rooms" do
    for username <- [String.duplicate("a", 300), String.duplicate("👨‍👩‍👧", 32)] do
      result =
        LobbyPage.command(:create_room, %{room_name: "general"}, %Server{
          session: %{"holodeck_chat_username" => username}
        })

      assert result.next_action.name == :show
      assert result.next_action.target == "toast"

      assert result.next_action.params == %{
               message: "Usernames can be at most 32 characters",
               variant: :error
             }
    end

    assert Holodeck.Chat.list_rooms() == []
  end
end
