defmodule HolodeckWeb.Poll.PollPage do
  use HolodeckWeb, :page

  alias Holodeck.Polls

  route "/poll"

  layout HolodeckWeb.Layout, title: "Polls · Holodeck"

  @recent_limit 10

  def init(_params, component, server) do
    # New polls and votes are broadcast here, so the list stays live without polling.
    {put_state(component, recent_polls: Polls.recent_polls()),
     put_subscription(server, Polls.recent_channel())}
  end

  def action(:create_poll, params, component) do
    put_command(component, :create_poll, params)
  end

  def action(:poll_added, %{entry: entry}, component) do
    recent_polls =
      [entry | Enum.reject(component.state.recent_polls, &(&1.poll.id == entry.poll.id))]
      |> Enum.take(@recent_limit)

    put_state(component, :recent_polls, recent_polls)
  end

  def action(:vote_recorded, %{poll_id: poll_id}, component) do
    recent_polls =
      Enum.map(component.state.recent_polls, fn entry ->
        if entry.poll.id == poll_id, do: %{entry | vote_count: entry.vote_count + 1}, else: entry
      end)

    put_state(component, :recent_polls, recent_polls)
  end

  def action(:poll_created, params, component) do
    put_page(component, HolodeckWeb.Poll.ResultPage, poll_id: params.poll.id)
  end

  def command(:create_poll, params, server) do
    case Polls.create_poll(params.event) do
      {:ok, poll} ->
        server
        |> put_broadcast(Polls.recent_channel(), :poll_added, entry: %{poll: poll, vote_count: 0})
        |> put_action(:poll_created, %{poll: poll})

      {:error, _reason} ->
        put_action(server,
          name: :show,
          target: "toast",
          params: %{message: "All fields are required", variant: :error}
        )
    end
  end
end
