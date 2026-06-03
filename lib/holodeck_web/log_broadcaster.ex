defmodule HolodeckWeb.LogBroadcaster do
  @behaviour :logger_handler

  def attach do
    :logger.add_handler(__MODULE__, __MODULE__, %{})
  end

  @impl :logger_handler
  def log(%{level: level, msg: {:string, msg}, meta: meta} = event, _config) do
    Task.start(fn ->
      Hologram.Realtime.broadcast_action(
        {:dashboard, "logs"},
        :logger,
        %{level: level, msg: msg, meta: meta}
      )
    end)
  end

  def log(_event, _config), do: :ok
end
