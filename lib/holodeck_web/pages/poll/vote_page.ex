defmodule HolodeckWeb.Poll.VotePage do
  use HolodeckWeb, :page
  use Hologram.JS

  alias Holodeck.Polls

  route "/poll/:poll_id/vote"

  param :poll_id, :string

  layout HolodeckWeb.Chat.Layout

  def init(params, component, _server) do
    poll = Polls.get_poll(params.poll_id)

    put_state(component, poll: poll)
  end

  def action(:vote, params, component) do
    put_command(component, :vote, %{
      answer_number: params.answer_number,
      poll_id: component.state.poll.id
    })
  end

  def action(:vote_complete, _params, component) do
    put_page(component, HolodeckWeb.Poll.ResultPage, poll_id: component.state.poll.id)
  end

  def command(:vote, params, server) do
    case Polls.vote(params.poll_id, params.answer_number) do
      {:ok, _result} ->
        put_action(server, :vote_complete)

      {:error, _reason} ->
        put_action(server,
          name: :show,
          target: "toast",
          params: %{message: "Could not submit your vote. Please try again.", variant: :error}
        )
    end
  end
end
