defmodule HolodeckWeb.PollBrowserTest do
  use ExUnit.Case, async: false
  use Wallaby.Feature

  import Holodeck.BrowserHelpers

  alias HolodeckWeb.Poll.{ResultPage, VotePage}

  @moduletag :e2e

  setup tags do
    Holodeck.DataCase.setup_sandbox(tags)

    {:ok, poll} =
      Holodeck.Polls.create_poll(%{
        question: "Which framework?",
        answer_1: "Hologram",
        answer_2: "Phoenix",
        answer_3: "Rails",
        answer_4: "Django"
      })

    %{poll: poll}
  end

  @sessions 2
  feature "a vote updates results in another browser without reloading", %{
    sessions: [voter, observer],
    poll: poll
  } do
    observer = visit_page(observer, ResultPage, poll_id: poll.id)

    observer
    |> assert_has(Query.css("#poll-vote-total[data-vote-count='0']"))
    |> find(Query.css("#poll-summary li", text: "Hologram"), fn row ->
      assert_has(row, Query.css("span", text: "0 · 0%"))
    end)

    voter
    |> visit_page(VotePage, poll_id: poll.id)
    |> click(Query.css("#vote-option-1"))
    |> assert_has(Query.css("#poll-voted"))
    |> assert_has(Query.css("#poll-vote-total[data-vote-count='1']"))

    observer
    |> assert_has(Query.css("#poll-vote-total[data-vote-count='1']"))
    |> find(Query.css("#poll-summary li", text: "Hologram"), fn row ->
      assert_has(row, Query.css("span", text: "1 · 100%"))
    end)
    |> refute_has(Query.css("#poll-voted"))
  end
end
