defmodule HolodeckWeb.Components.Kanban.Column do
  use HolodeckWeb, :component

  prop :column, :string
  prop :label, :string
  prop :cards, :list
  prop :disabled, :boolean

  def action(:request_move, params, component) do
    put_action(component, name: :request_move, target: "kanban-board", params: params)
  end
end
