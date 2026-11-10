defmodule HolodeckWeb.Poll.ResultPage do
  use HolodeckWeb, :page
  use Hologram.JS

  alias Holodeck.Polls

  js_import :Chart, from: "chart.js/auto"
  js_import :copyVoteLink, from: "./clipboard.mjs"

  route "/poll/:poll_id"

  param :poll_id, :string

  layout HolodeckWeb.Layout, title: "Poll results · Holodeck"

  def init(params, component, server) do
    poll = Polls.get_poll(params.poll_id)

    if poll do
      answers = Polls.get_answers_for(poll.id)

      component =
        component
        |> put_state(
          poll: poll,
          answers: answers,
          frequencies: Enum.frequencies_by(answers, & &1.answer_number),
          voted?: poll.id in get_session(server, :voted_poll_ids, []),
          vote_url: "/poll/#{poll.id}/vote",
          breadcrumbs: [{"Polls", HolodeckWeb.Poll.PollPage}, {"Results", nil}]
        )
        |> put_action(:init_chart)

      server = put_subscription(server, {:poll_result, poll.id})

      {component, server}
    else
      {put_state(component,
         poll: nil,
         title: "Poll not found · Holodeck",
         breadcrumbs: [{"Polls", HolodeckWeb.Poll.PollPage}, {"Poll not found", nil}]
       ), server}
    end
  end

  def action(:init_chart, _params, component) do
    labels = [
      component.state.poll.answer_1,
      component.state.poll.answer_2,
      component.state.poll.answer_3,
      component.state.poll.answer_4
    ]

    frequencies = component.state.frequencies

    counts = [
      Map.get(frequencies, 1, 0),
      Map.get(frequencies, 2, 0),
      Map.get(frequencies, 3, 0),
      Map.get(frequencies, 4, 0)
    ]

    buffer = JS.new(:Float64Array, [counts])

    chart =
      JS.new(:Chart, [
        "poll-results-chart",
        %{
          type: "bar",
          data: %{
            labels: labels,
            datasets: [
              %{label: "Votes", data: buffer, backgroundColor: "#a78bfa", borderRadius: 5}
            ]
          },
          options: %{
            responsive: true,
            maintainAspectRatio: false,
            indexAxis: "y",
            scales: %{
              x: %{
                beginAtZero: true,
                ticks: %{precision: 0, color: "#a1a1aa"},
                grid: %{color: "#27272a"}
              },
              y: %{ticks: %{color: "#d4d4d8"}, grid: %{display: false}}
            },
            plugins: %{legend: %{display: false}}
          }
        }
      ])

    location = JS.get(:window, :location)
    vote_url = JS.get(location, :origin) <> "/poll/#{component.state.poll.id}/vote"

    put_state(component, chart: chart, buffer: buffer, vote_url: vote_url)
  end

  def action(:copy_link, _params, component) do
    copied? = JS.call(:copyVoteLink, [component.state.vote_url]) |> Task.await()

    if copied? do
      put_action(component,
        name: :show,
        target: "toast",
        params: %{message: "Link copied", variant: :success}
      )
    else
      select_link(component)
    end
  end

  def action(:update_results, params, component) do
    result = params.result
    answers = component.state.answers
    buffer = component.state.buffer
    chart = component.state.chart
    n = result.answer_number

    index = n - 1
    current = JS.get(buffer, index)
    JS.set(buffer, index, current + 1)
    JS.call(chart, :update, [])

    frequencies = Map.update(component.state.frequencies, n, 1, fn c -> c + 1 end)

    answers = [result | answers]

    put_state(component, frequencies: frequencies, answers: answers)
  end

  defp select_link(component) do
    input = JS.call(:document, :getElementById, ["poll-vote-url"])
    JS.call(input, :focus, [])
    JS.call(input, :select, [])

    put_action(component,
      name: :show,
      target: "toast",
      params: %{message: "Link selected — copy it to share", variant: :info}
    )
  end
end
