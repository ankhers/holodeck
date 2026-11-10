defmodule HolodeckWeb.Components.AppShellTest do
  use ExUnit.Case, async: true

  alias Hologram.Template.Renderer
  alias Hologram.Template.Renderer.Env
  alias HolodeckWeb.Components.AppShell

  test "renders linked parent breadcrumbs, the current page, and slotted content" do
    document =
      render_shell(breadcrumbs: [{"Polls", HolodeckWeb.Poll.PollPage}, {"Results", nil}])

    assert text(document, "nav a[href='/']") == "H Home"
    assert text(document, "nav a[href='/poll']") == "Polls"
    assert text(document, "nav [aria-current='page']") == "Results"
    assert text(document, "#content") == "Page content"
    assert count(document, ".hd-grain") == 1
    assert count(document, ".hd-glow") == 1
  end

  test "defaults to the home shell without a status pill" do
    document = render_shell([])
    assert count(document, "nav.mb-12") == 1
    assert count(document, "nav .hd-live-dot") == 0
    assert count(document, "nav [aria-current]") == 0
  end

  test "keeps the full-height room's content in the outer flex layout" do
    document =
      render_shell(full_height: true, breadcrumbs: [{"Room not found", nil}])

    assert count(document, ".h-dvh.flex.flex-col.overflow-hidden > .contents > #content") == 1
    assert count(document, "nav.shrink-0") == 1
    assert count(document, ".max-w-\\[1180px\\]") == 0
  end

  test "shows the dashboard connection pill when requested" do
    document = render_shell(connected: true, breadcrumbs: [{"Dashboard", nil}])
    assert count(document, "nav.justify-between .hd-live-dot") == 1
  end

  test "every page uses the shared layout and declares a distinct title" do
    pages = [
      HolodeckWeb.HomePage,
      HolodeckWeb.Chat.LobbyPage,
      HolodeckWeb.Chat.RoomPage,
      HolodeckWeb.Dashboard.DashboardPage,
      HolodeckWeb.Poll.PollPage,
      HolodeckWeb.Poll.ResultPage,
      HolodeckWeb.Poll.VotePage
    ]

    titles =
      Enum.map(pages, fn page ->
        assert page.__layout_module__() == HolodeckWeb.Layout
        page.__layout_props__()[:title]
      end)

    assert Enum.all?(titles, &String.ends_with?(&1, " · Holodeck"))
    assert length(Enum.uniq(titles)) == length(pages)
  end

  defp render_shell(props) do
    props_dom = Enum.map(props, fn {key, value} -> {to_string(key), [expression: {value}]} end)
    children = [{:element, "p", [{"id", [text: "content"]}], [text: "Page content"]}]

    {html, _, _} =
      Renderer.render_dom({:component, AppShell, props_dom, children}, %Env{}, %Hologram.Server{})

    LazyHTML.from_fragment(html)
  end

  defp text(document, selector) do
    document
    |> LazyHTML.query(selector)
    |> LazyHTML.text()
    |> String.trim()
    |> String.replace(~r/\s+/, " ")
  end

  defp count(document, selector), do: document |> LazyHTML.query(selector) |> Enum.count()
end
