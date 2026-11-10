defmodule HolodeckWeb.Poll.PageChromeTest do
  use Holodeck.DataCase, async: false

  alias Hologram.Component
  alias Hologram.Server
  alias Holodeck.Polls
  alias HolodeckWeb.Poll.{PollPage, ResultPage, VotePage}

  test "missing results and vote pages identify the missing poll" do
    for poll_id <- ["not-a-uuid", Ecto.UUID.generate()] do
      {results, _server} = ResultPage.init(%{poll_id: poll_id}, %Component{}, %Server{})
      vote = VotePage.init(%{poll_id: poll_id}, %Component{}, %Server{})

      for component <- [results, vote] do
        assert component.state.poll == nil
        assert component.state.title == "Poll not found · Holodeck"
        assert component.state.breadcrumbs == [{"Polls", PollPage}, {"Poll not found", nil}]
      end
    end
  end

  test "results render frequencies immediately and remember this session's vote" do
    Holodeck.HologramHelpers.ensure_pubsub_started()

    {:ok, poll} =
      Polls.create_poll(%{
        question: "Ready?",
        answer_1: "A",
        answer_2: "B",
        answer_3: "C",
        answer_4: "D"
      })

    server = VotePage.command(:vote, %{poll_id: poll.id, answer_number: 2}, %Server{})
    assert server.session["holodeck_voted_poll_ids"] == [poll.id]

    {results, _} = ResultPage.init(%{poll_id: poll.id}, %Component{}, server)
    assert results.state.frequencies == %{2 => 1}
    assert results.state.voted?
    assert results.state.vote_url == "/poll/#{poll.id}/vote"

    {visitor_results, _} = ResultPage.init(%{poll_id: poll.id}, %Component{}, %Server{})
    refute visitor_results.state.voted?
    assert length(PollPage.init(%{}, %Component{}, %Server{}).state.recent_polls) == 1
  end

  test "vote history retains only the most recent forty poll ids" do
    Holodeck.HologramHelpers.ensure_pubsub_started()

    {:ok, poll} =
      Polls.create_poll(%{
        question: "Ready?",
        answer_1: "A",
        answer_2: "B",
        answer_3: "C",
        answer_4: "D"
      })

    history = for _ <- 1..45, do: Ecto.UUID.generate()
    server = %Server{session: %{"holodeck_voted_poll_ids" => history}}

    updated = VotePage.command(:vote, %{poll_id: poll.id, answer_number: 1}, server)

    assert updated.session["holodeck_voted_poll_ids"] == [poll.id | Enum.take(history, 39)]
    assert length(updated.session["holodeck_voted_poll_ids"]) == 40
  end

  test "a session cannot submit another vote and the vote page remembers it" do
    Holodeck.HologramHelpers.ensure_pubsub_started()

    {:ok, poll} =
      Polls.create_poll(%{
        question: "Ready?",
        answer_1: "A",
        answer_2: "B",
        answer_3: "C",
        answer_4: "D"
      })

    params = %{poll_id: poll.id, answer_number: 1}
    server = VotePage.command(:vote, params, %Server{})
    repeated = VotePage.command(:vote, %{params | answer_number: 2}, server)

    assert length(Polls.get_answers_for(poll.id)) == 1
    assert repeated.next_action.name == :show
    assert repeated.next_action.target == "toast"

    assert repeated.next_action.params == %{
             message: "You've already voted on this poll",
             variant: :info
           }

    assert VotePage.init(%{poll_id: poll.id}, %Component{}, repeated).state.voted?
    refute VotePage.init(%{poll_id: poll.id}, %Component{}, %Server{}).state.voted?
  end

  test "invalid votes do not mark the session as voted" do
    server = VotePage.command(:vote, %{poll_id: "invalid", answer_number: 1}, %Server{})
    refute Map.has_key?(server.session, "holodeck_voted_poll_ids")
  end

  test "existing results and vote pages retain their section breadcrumbs" do
    {:ok, poll} =
      Polls.create_poll(%{
        question: "Favourite colour?",
        answer_1: "Red",
        answer_2: "Blue",
        answer_3: "Green",
        answer_4: "Yellow"
      })

    {results, _server} = ResultPage.init(%{poll_id: poll.id}, %Component{}, %Server{})
    vote = VotePage.init(%{poll_id: poll.id}, %Component{}, %Server{})

    assert results.state.poll == poll
    assert results.state.breadcrumbs == [{"Polls", PollPage}, {"Results", nil}]
    assert vote.state.poll == poll
    assert vote.state.title == "Vote · Holodeck"
    assert vote.state.breadcrumbs == [{"Polls", PollPage}, {"Vote", nil}]
  end
end
