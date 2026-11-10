defmodule HolodeckWeb.Poll.PollPage do
  use HolodeckWeb, :page

  alias Holodeck.Polls

  route "/poll"

  layout HolodeckWeb.Layout, title: "Polls · Holodeck"

  def init(_params, component, _server) do
    put_state(component, recent_polls: Polls.recent_polls())
  end

  def action(:create_poll, params, component) do
    put_command(component, :create_poll, params)
  end

  def action(:poll_created, params, component) do
    put_page(component, HolodeckWeb.Poll.ResultPage, poll_id: params.poll.id)
  end

  def command(:create_poll, params, server) do
    case Polls.create_poll(params.event) do
      {:ok, poll} ->
        put_action(server, :poll_created, %{poll: poll})

      {:error, _reason} ->
        put_action(server,
          name: :show,
          target: "toast",
          params: %{message: "All fields are required", variant: :error}
        )
    end
  end
end
