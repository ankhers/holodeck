defmodule HolodeckWeb.LogBroadcaster do
  @behaviour :logger_handler

  @ansi_escape ~r/\e(?:\[[0-?]*[ -\/]*[@-~]|\][^\a\e]*(?:\a|\e\\)|[@-_])/

  def attach do
    :logger.add_handler(__MODULE__, __MODULE__, %{})
  end

  @impl :logger_handler
  def log(%{level: level, msg: {:string, msg}, meta: meta}, _config) do
    min_level = Application.get_env(:holodeck, __MODULE__, []) |> Keyword.get(:min_level, :info)

    if :logger.compare_levels(level, min_level) != :lt do
      payload = %{
        level: level,
        msg: Regex.replace(@ansi_escape, IO.chardata_to_string(msg), ""),
        time: meta.time,
        module: module_name(meta)
      }

      Task.start(fn ->
        Hologram.Realtime.broadcast_action({:dashboard, "logs"}, :logger, payload)
      end)
    end

    :ok
  end

  def log(_event, _config), do: :ok

  defp module_name(%{mfa: {module, _function, _arity}}),
    do: module |> Atom.to_string() |> String.replace_prefix("Elixir.", "")

  defp module_name(_meta), do: ""
end
