defmodule HolodeckWeb.Components.Kanban.Column do
  use HolodeckWeb, :component

  prop :column, :string
  prop :label, :string
  prop :cards, :list
  prop :disabled, :boolean

  # Moves hop through Column to demonstrate chained targeted actions; deletes go Card → Board directly.
  def action(:request_move, params, component) do
    put_action(component, name: :request_move, target: "kanban-board", params: params)
  end
end
