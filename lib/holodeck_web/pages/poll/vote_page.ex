defmodule HolodeckWeb.Poll.VotePage do
  use HolodeckWeb, :page
  use Hologram.JS

  alias Holodeck.Polls

  route "/poll/:poll_id/vote"

  param :poll_id, :string

  layout HolodeckWeb.Layout, title: "Vote · Holodeck"

  def init(params, component, server) do
    poll = Polls.get_poll(params.poll_id)

    put_state(component,
      poll: poll,
      voted?: params.poll_id in get_session(server, :voted_poll_ids, []),
      title: if(poll, do: "Vote · Holodeck", else: "Poll not found · Holodeck"),
      breadcrumbs: [
        {"Polls", HolodeckWeb.Poll.PollPage},
        {if(poll, do: "Vote", else: "Poll not found"), nil}
      ]
    )
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
    # Demo-only session protection: clearing cookies (or aging out of history) allows another vote.
    if params.poll_id in get_session(server, :voted_poll_ids, []) do
      put_action(server,
        name: :show,
        target: "toast",
        params: %{message: "You've already voted on this poll", variant: :info}
      )
    else
      submit_vote(params, server)
    end
  end

  defp submit_vote(params, server) do
    case Polls.vote(params.poll_id, params.answer_number) do
      {:ok, _result} ->
        voted_poll_ids =
          [params.poll_id | get_session(server, :voted_poll_ids, [])]
          |> Enum.uniq()
          |> Enum.take(40)

        server
        |> put_session(:voted_poll_ids, voted_poll_ids)
        |> put_action(:vote_complete)

      {:error, _reason} ->
        put_action(server,
          name: :show,
          target: "toast",
          params: %{message: "Could not submit your vote. Please try again.", variant: :error}
        )
    end
  end
end
