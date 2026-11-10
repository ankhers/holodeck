defmodule HolodeckWeb.Poll.ResultPage do
  use HolodeckWeb, :page
  use Hologram.JS

  alias Holodeck.Polls

  js_import :Chart, from: "chart.js/auto"

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
          frequencies: %{},
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

    frequencies =
      Enum.frequencies_by(component.state.answers, fn a ->
        a.answer_number
      end)

    counts = [
      Map.get(frequencies, 1),
      Map.get(frequencies, 2),
      Map.get(frequencies, 3),
      Map.get(frequencies, 4)
    ]

    buffer = JS.new(:Float64Array, [counts])

    chart =
      JS.new(:Chart, [
        "poll-results-chart",
        %{
          type: "bar",
          data: %{labels: labels, datasets: [%{label: "Votes", data: buffer}]},
          options: %{
            responsive: true,
            maintainAspectRatio: false,
            scales: %{y: %{beginAtZero: true, ticks: %{precision: 0}}},
            plugins: %{legend: %{display: false}}
          }
        }
      ])

    put_state(component, chart: chart, frequencies: frequencies, buffer: buffer)
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
end
