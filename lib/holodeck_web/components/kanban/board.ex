defmodule HolodeckWeb.Components.Kanban.Board do
  use HolodeckWeb, :component
  use Hologram.JS

  alias Holodeck.Kanban

  js_import :install, from: "./drag_drop.js", as: :install_drag_drop

  def init(_props, component, server) do
    component =
      component
      |> put_state(
        confirmed: Kanban.snapshot(),
        pending: nil,
        busy: nil,
        request_seq: 0,
        draft_title: "",
        error: "",
        status: "",
        reset_confirmation: nil
      )
      |> put_action(:mount_drag_drop)

    {component, put_subscription(server, {:kanban, "public"})}
  end

  def action(:mount_drag_drop, _params, component) do
    JS.call(:install_drag_drop, ["kanban-board-root", "kanban-board"])
    put_command(component, :snapshot)
  end

  def action(:sync, _params, component), do: put_command(component, :snapshot)

  def action(:update_draft, params, component) do
    put_state(component, :draft_title, params.event.value)
  end

  def action(:confirm_reset, _params, component) do
    if component.state.busy do
      component
    else
      put_state(component, :reset_confirmation, component.state.confirmed.revision)
    end
  end

  def action(:cancel_reset, _params, component) do
    put_state(component, :reset_confirmation, nil)
  end

  def action(:request_move, params, component) do
    card = Enum.find(component.state.confirmed.cards, &(&1.id == params.card_id))

    cond do
      component.state.busy != nil -> component
      card == nil -> component
      params.destination not in ~w(todo doing done) -> component
      params.destination == card.column -> component
      true -> begin_mutation(component, :move_card, params)
    end
  end

  def action(:add_card, _params, component) do
    if component.state.busy || String.trim(component.state.draft_title) == "" do
      component
    else
      begin_mutation(component, :add_card, %{title: component.state.draft_title})
    end
  end

  def action(:delete_card, params, component) do
    if component.state.busy, do: component, else: begin_mutation(component, :delete_card, params)
  end

  def action(:reset_board, _params, component) do
    if component.state.busy || component.state.reset_confirmation == nil do
      component
    else
      begin_mutation(component, :reset_board, %{
        confirmed: true,
        expected_revision: component.state.reset_confirmation
      })
    end
  end

  def action(:receive_snapshot, params, component), do: reconcile(component, params.snapshot)

  def action(:move_settled, params, component) do
    component = reconcile(component, params.snapshot)

    if component.state.busy == params.seq do
      component
      |> put_state(
        busy: nil,
        pending: nil,
        error: message(params.status),
        status: if(params.status == :ok, do: "Board updated.", else: ""),
        draft_title:
          if(params.status == :ok && params.operation == :add_card,
            do: "",
            else: component.state.draft_title
          ),
        reset_confirmation: nil
      )
    else
      component
    end
  end

  def action(:move_timeout, params, component) do
    if component.state.busy == params.seq do
      component
      |> put_state(
        busy: nil,
        pending: nil,
        error: "Update timed out. Syncing the board; no retry was sent."
      )
      |> put_command(:snapshot)
    else
      component
    end
  end

  def command(:snapshot, _params, server) do
    put_action(server, :receive_snapshot, snapshot: Kanban.snapshot())
  end

  def command(operation, params, server)
      when operation in [:move_card, :add_card, :delete_card, :reset_board] do
    result =
      case operation do
        :move_card -> Kanban.move_card(params)
        :add_card -> Kanban.add_card(params)
        :delete_card -> Kanban.delete_card(params)
        :reset_board -> Kanban.reset_board(params)
      end

    {server, status, snapshot} =
      case result do
        {:ok, snapshot} ->
          {put_broadcast(server, {:kanban, "public"}, :receive_snapshot, snapshot: snapshot), :ok,
           snapshot}

        {:error, reason, snapshot} ->
          {server, reason, snapshot}
      end

    put_action(server, :move_settled,
      seq: params.seq,
      operation: operation,
      status: status,
      snapshot: snapshot
    )
  end

  def display_cards(confirmed, nil), do: confirmed.cards

  def display_cards(confirmed, pending) do
    card = Enum.find(confirmed.cards, &(&1.id == pending.card_id))

    if card do
      Enum.reject(confirmed.cards, &(&1.id == pending.card_id)) ++
        [%{card | column: pending.destination}]
    else
      confirmed.cards
    end
  end

  defp begin_mutation(component, operation, params) do
    seq = component.state.request_seq + 1
    params = Map.put(params, :seq, seq)

    component
    |> put_state(
      request_seq: seq,
      busy: seq,
      pending: if(operation == :move_card, do: params, else: nil),
      error: "",
      status: "Updating…"
    )
    |> put_command(operation, params)
    |> put_action(name: :move_timeout, delay: 10_000, params: %{seq: seq})
  end

  defp reconcile(component, snapshot) do
    if snapshot.revision > component.state.confirmed.revision do
      pending = component.state.pending

      unchanged? =
        pending == nil ||
          Enum.any?(snapshot.cards, fn card ->
            card.id == pending.card_id && card.version == pending.expected_version
          end)

      put_state(component,
        confirmed: snapshot,
        pending: if(unchanged?, do: pending, else: nil),
        error: if(unchanged?, do: component.state.error, else: message(:conflict))
      )
    else
      component
    end
  end

  defp message(:ok), do: ""
  defp message(:conflict), do: "This card changed in another browser. Showing the latest board."

  defp message(:cap),
    do: "This public board is limited to 30 cards. Delete a card to add another."

  defp message(:invalid_title), do: "Use a title with 1–120 trimmed characters."

  defp message(:cooldown),
    do: "Please wait: the public board can only be reset once every 60 seconds."

  defp message(:confirmation_required), do: "Confirm the reset first."
  defp message(_), do: "Unable to update the board. Sync and try again."
end
