defmodule HolodeckWeb.Components.PageHeaderTest do
  use Holodeck.DataCase, async: false

  alias Hologram.{Component, Server}
  alias Hologram.Template.Renderer
  alias Hologram.Template.Renderer.Env
  alias HolodeckWeb.Chat.LobbyPage
  alias HolodeckWeb.Dashboard.DashboardPage
  alias HolodeckWeb.Kanban.BoardPage
  alias HolodeckWeb.Life.LifePage
  alias HolodeckWeb.Poll.PollPage

  defp render(page, assigns) do
    {tree, _registry, _server} =
      Renderer.render_tree(page.template().(assigns), %Env{}, %Server{})

    tree |> Renderer.print_dom() |> LazyHTML.from_fragment()
  end

  defp state({%Component{} = component, _server}), do: component.state
  defp state(%Component{} = component), do: component.state

  test "every app page opens with the shared header and a single h1" do
    pages = [
      {LobbyPage, state(LobbyPage.init(%{}, %Component{}, %Server{})), "Chat",
       "Commands · broadcasts · sessions"},
      {DashboardPage, state(DashboardPage.init(%{}, %Component{}, %Server{})), "Dashboard",
       "Server ticks · log streaming"},
      {PollPage, state(PollPage.init(%{}, %Component{}, %Server{})), "Polls",
       "JS interop · Chart.js"},
      {LifePage, state(LifePage.init(%{}, %Component{}, %Server{})), "Game of Life",
       "Client-side Elixir · delayed actions"},
      {BoardPage, %{}, "Shared Kanban", "Nested components · targeted actions"}
    ]

    for {page, assigns, title, kicker} <- pages do
      document = render(page, assigns)
      headings = LazyHTML.query(document, "h1")

      assert Enum.count(headings) == 1, "#{inspect(page)}: #{LazyHTML.to_html(headings)}"
      assert document |> LazyHTML.query("header h1") |> LazyHTML.text() == title
      assert document |> LazyHTML.query("header") |> LazyHTML.text() =~ kicker
    end
  end

  test "slot content renders beside the heading" do
    document = render(BoardPage, %{})
    assert document |> LazyHTML.query("header #kanban-sync") |> Enum.count() == 1
    assert document |> LazyHTML.query("header #kanban-reset") |> Enum.count() == 1
  end
end
