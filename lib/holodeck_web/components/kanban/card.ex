defmodule HolodeckWeb.Components.Kanban.Card do
  use HolodeckWeb, :component

  prop :card, :map
  prop :column_cid, :string
  prop :disabled, :boolean

  # New cards mount in the browser; the initial board mounts on the server.
  def init(_props, component), do: put_state(component, :delete_confirmation, false)
  def init(props, component, _server), do: init(props, component)

  def action(:move, params, component) do
    if component.props.disabled do
      component
    else
      put_action(component,
        name: :request_move,
        target: component.props.column_cid,
        params: %{
          card_id: component.props.card.id,
          expected_version: component.props.card.version,
          destination: params.destination
        }
      )
    end
  end

  def action(:confirm_delete, _params, component),
    do: put_state(component, :delete_confirmation, true)

  def action(:cancel_delete, _params, component),
    do: put_state(component, :delete_confirmation, false)

  def action(:delete, _params, component) do
    if component.props.disabled || !component.state.delete_confirmation do
      component
    else
      component
      |> put_state(:delete_confirmation, false)
      |> put_action(
        name: :delete_card,
        target: "kanban-board",
        params: %{
          card_id: component.props.card.id,
          expected_version: component.props.card.version
        }
      )
    end
  end
end
