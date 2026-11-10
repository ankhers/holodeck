defmodule HolodeckWeb.Poll.PageChromeTest do
  use Holodeck.DataCase, async: true

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
