defmodule HolodeckWeb.Dashboard.DashboardPage do
  use HolodeckWeb, :page

  alias Holodeck.Dashboard

  route "/dashboard"

  layout HolodeckWeb.Chat.Layout

  @tick_delay 5_000

  def init(_params, component, server) do
    process_sort = get_session(server, "holodeck_dashboard_process_sort", :memory)

    system_metrics = Dashboard.system_metrics(process_sort: process_sort)

    component =
      component
      |> put_state(system_metrics: system_metrics, process_sort: process_sort, log_msgs: [])
      |> put_action(name: :tick, delay: @tick_delay)

    server = put_subscription(server, {:dashboard, "logs"})

    {component, server}
  end

  def action(:logger, params, component) do
    put_state(component, log_msgs: [params | component.state.log_msgs])
  end

  def action(:sort_memory, _params, component) do
    component
    |> put_command(:process_sort, %{order: :memory})
    |> put_state(process_sort: :memory)
  end

  def action(:sort_reductions, _params, component) do
    component
    |> put_command(:process_sort, %{order: :reductions})
    |> put_state(process_sort: :reductions)
  end

  def action(:sort_pid, _params, component) do
    component
    |> put_command(:process_sort, %{order: :pid})
    |> put_state(process_sort: :pid)
  end

  def action(:tick, _params, component) do
    put_command(component, :tick)
  end

  def action(:tick_update, params, component) do
    component
    |> put_state(system_metrics: params)
    |> put_action(name: :tick, delay: @tick_delay)
  end

  def command(:process_sort, params, server) do
    put_session(server, "holodeck_dashboard_process_sort", params.order)
  end

  def command(:tick, _params, server) do
    process_sort = get_session(server, "holodeck_dashboard_process_sort", :memory)

    system_metrics = Dashboard.system_metrics(process_sort: process_sort)

    put_action(server, :tick_update, system_metrics)
  end

  def bar_colour(percent) when percent >= 80, do: "#f87171"
  def bar_colour(percent) when percent >= 60, do: "#fbbf24"
  def bar_colour(_percent), do: "#60a5fa"

  def format_percent(f), do: :erlang.float_to_binary(f / 1, decimals: 2)

  def format_bytes(bytes) when bytes >= 1_099_511_627_776,
    do: "#{Float.round(bytes / 1_099_511_627_776, 1)} TB"

  def format_bytes(bytes) when bytes >= 1_073_741_824,
    do: "#{Float.round(bytes / 1_073_741_824, 1)} GB"

  def format_bytes(bytes) when bytes >= 1_048_576,
    do: "#{Float.round(bytes / 1_048_576, 1)} MB"

  def format_bytes(bytes) when bytes >= 1_024,
    do: "#{Float.round(bytes / 1_024, 1)} KB"

  def format_bytes(bytes),
    do: "#{bytes} B"

  def format_uptime(ms) do
    total_seconds = div(ms, 1000)
    days = div(total_seconds, 86400)
    hours = div(rem(total_seconds, 86400), 3600)
    minutes = div(rem(total_seconds, 3600), 60)

    cond do
      days > 0 -> "#{days}d #{hours}h"
      hours > 0 -> "#{hours}h #{minutes}m"
      true -> "#{minutes}m"
    end
  end

  def format_integer(n) when is_integer(n) do
    n
    |> Integer.to_string()
    |> String.graphemes()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.join(",")
    |> String.reverse()
  end

  def sort_button_class(a, a), do: "hd-sort-btn-active"
  def sort_button_class(_a, _b), do: "hd-sort-btn"

  def log_level(%{level: level}), do: level |> Atom.to_string() |> String.upcase()

  def format_time(timestamp),
    do: timestamp |> DateTime.from_unix!(:microsecond) |> Calendar.strftime("%H:%M:%S")

  def log_module(log) do
    if Map.has_key?(log.meta, :mfa) do
      log.meta.mfa
      |> elem(0)
      |> Atom.to_string()
      |> String.replace_prefix("Elixir.", "")
    else
      ""
    end
  end

  def log_level_text_colour(%{level: :warning}), do: "#fbbf24"
  def log_level_text_colour(%{level: :error}), do: "#f87171"
  def log_level_text_colour(_log), do: "#60a5fa"

  def log_level_background_colour(%{level: :warning}), do: "rgba(251,191,36,0.1)"
  def log_level_background_colour(%{level: :error}), do: "rgba(248,113,113,0.1)"
  def log_level_background_colour(_log), do: "rgba(96,165,250,0.1)"
end
