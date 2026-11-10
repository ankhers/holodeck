defmodule HolodeckWeb.Kanban.BoardPageTest do
  use Holodeck.DataCase, async: false

  alias Hologram.Server
  alias Hologram.Template.Renderer
  alias Hologram.Template.Renderer.Env
  alias HolodeckWeb.Kanban.BoardPage

  test "page route, title, breadcrumbs, public controls and nested stable cids" do
    assert BoardPage.__route__() == "/kanban"
    assert BoardPage.__layout_props__()[:title] == "Shared Kanban · Holodeck"

    {tree, registry, server} = Renderer.render_tree(BoardPage.template().(%{}), %Env{}, %Server{})
    document = tree |> Renderer.print_dom() |> LazyHTML.from_fragment()

    for selector <- [
          "#kanban-board-root",
          "#kanban-add",
          "#kanban-title[maxlength='120']",
          "#kanban-sync:not([disabled])",
          "#kanban-reset",
          "#kanban-status[aria-live='polite']",
          "nav [aria-current='page']",
          "#kanban-column-todo[data-column='todo']",
          "#kanban-column-doing[data-column='doing']",
          "#kanban-column-done[data-column='done']"
        ] do
      assert document |> LazyHTML.query(selector) |> Enum.count() == 1,
             "missing #{selector}: #{LazyHTML.to_html(document)}"
    end

    assert document |> LazyHTML.query("nav [aria-current='page']") |> LazyHTML.text() ==
             "Shared Kanban"

    assert document |> LazyHTML.query("[data-card-id][draggable='true']") |> Enum.count() == 6
    assert Map.has_key?(registry, "kanban-board")
    assert Map.has_key?(registry, "kanban-column-todo")
    assert Enum.count(Map.keys(registry), &String.starts_with?(&1, "kanban-card-")) == 6
    assert length(server.subscriptions) == 1
  end

  test "home advertises the shared board with the designed copy" do
    {tree, _, _} = Renderer.render_tree(HolodeckWeb.HomePage.template().(%{}), %Env{}, %Server{})
    document = tree |> Renderer.print_dom() |> LazyHTML.from_fragment()
    card = LazyHTML.query(document, "#home-demos a[href='/kanban']")
    assert Enum.count(card) == 1, LazyHTML.to_html(document)
    assert LazyHTML.text(card) =~ "Move cards together on a shared board."

    assert LazyHTML.text(card) =~
             "Nested stateful components · targeted actions · optimistic updates"
  end
end
