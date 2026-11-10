defmodule Holodeck.HologramHelpers do
  def ensure_pubsub_started do
    # Hologram may already own PubSub when HOLOGRAM_START=1 or Hologram.Test.setup() is used.
    if Process.whereis(Hologram.PubSub) == nil do
      ExUnit.Callbacks.start_supervised!({Phoenix.PubSub, name: Hologram.PubSub})
    end

    :ok
  end
end
