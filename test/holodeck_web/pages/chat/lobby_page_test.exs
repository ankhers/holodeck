defmodule HolodeckWeb.Chat.LobbyPageTest do
  use Holodeck.DataCase, async: true

  alias Hologram.Component
  alias Hologram.Server
  alias HolodeckWeb.Chat.LobbyPage

  test "the lobby displays the session username" do
    component =
      LobbyPage.init(%{}, %Component{}, %Server{
        session: %{"holodeck_chat_username" => "Alice"}
      })

    assert component.state.username == "Alice"
  end

  test "saving a username persists it before showing a success toast" do
    result = LobbyPage.command(:save_username, %{username: "Alice"}, %Server{})

    assert Server.get_session(result, "holodeck_chat_username") == "Alice"
    assert result.next_action.name == :show
    assert result.next_action.target == "toast"
    assert result.next_action.params == %{message: "Username saved", variant: :success}
  end
end
