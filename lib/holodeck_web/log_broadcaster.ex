defmodule HolodeckWeb.LogBroadcaster do
  @behaviour :logger_handler

  # Matches ANSI CSI controls, OSC sequences (including hyperlinks), and short escapes.
  @ansi_escape ~r/\e(?:\[[0-?]*[ -\/]*[@-~]|\][^\a\e]*(?:\a|\e\\)|[@-_])/
  @internal_request {__MODULE__, :internal_request}

  def attach do
    min_level = Application.get_env(:holodeck, __MODULE__, []) |> Keyword.fetch!(:min_level)

    :logger.add_handler(__MODULE__, __MODULE__, %{
      level: min_level,
      filters: [{:public_dashboard, {&__MODULE__.filter/2, nil}}]
    })
  end

  @doc false
  def filter(%{meta: %{crash_reason: _reason}}, _extra), do: :stop
  def filter(%{meta: %{mfa: {Plug.Debugger, _function, _arity}}}, _extra), do: :stop

  def filter(%{meta: %{mfa: {Phoenix.Logger, :phoenix_error_rendered, _arity}}}, _extra),
    do: :stop

  def filter(%{meta: %{domain: domain}} = event, _extra) when is_list(domain) do
    if :bandit in domain do
      :stop
    else
      filter_request(event)
    end
  end

  def filter(event, _extra), do: filter_request(event)

  @impl :logger_handler
  def log(%{msg: {:report, _report}}, _config), do: :ok

  def log(event, _config) do
    Task.start(fn ->
      payload = %{
        level: event.level,
        msg: Regex.replace(@ansi_escape, message_text(event.msg), ""),
        time: event.meta.time,
        module: module_name(event.meta)
      }

      Hologram.Realtime.broadcast_action({:dashboard, "logs"}, :logger, payload)
    end)

    :ok
  end

  # Phoenix emits start/stop logs in the request process, but omits the path on stop.
  defp filter_request(
         %{
           meta: %{mfa: {Phoenix.Logger, :phoenix_endpoint_start, _arity}},
           msg: {:string, [_method, 32, path]}
         } = event
       ) do
    internal? = internal_path?(path)
    Process.put(@internal_request, internal?)
    if internal?, do: :stop, else: event
  end

  defp filter_request(%{meta: %{mfa: {Phoenix.Logger, :phoenix_endpoint_stop, _arity}}} = event) do
    if Process.delete(@internal_request), do: :stop, else: event
  end

  defp filter_request(%{meta: meta} = event) do
    if internal_path?(Map.get(meta, :request_path)), do: :stop, else: event
  end

  defp internal_path?("/hologram/" <> _rest), do: true
  defp internal_path?(_path), do: false

  defp message_text({:string, msg}), do: text(msg)
  defp message_text({format, args}), do: format |> :io_lib.format(args) |> text()

  defp text(binary) when is_binary(binary), do: String.replace_invalid(binary)
  defp text(list) when is_list(list), do: Enum.map_join(list, &text/1)
  defp text(codepoint) when is_integer(codepoint), do: <<codepoint::utf8>>

  defp module_name(%{mfa: {module, _function, _arity}}),
    do: module |> Atom.to_string() |> String.replace_prefix("Elixir.", "")

  defp module_name(_meta), do: ""
end
