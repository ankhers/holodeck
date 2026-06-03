defmodule HolodeckWeb.Poll.PollPage do
  use HolodeckWeb, :page

  alias Holodeck.Polls

  route "/poll"

  layout HolodeckWeb.Chat.Layout

  def action(:create_poll, params, component) do
    put_command(component, :create_poll, params)
  end

  def command(:create_poll, params, server) do
    case Polls.create_poll(params.event) do
      {:ok, poll} ->
        # TODO: Move to answer page
        server

      {:error, reason} ->
        # TODO: Show error flash
        server
    end
  end
end
