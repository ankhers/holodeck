defmodule Holodeck.Dashboard do
  def system_metrics(opts) do
    process_sort = Keyword.get(opts, :process_sort, :memory)

    processes = Process.list()

    {sort_value, direction} =
      case process_sort do
        :memory -> {fn {_pid, info} -> info[:memory] end, :desc}
        :reductions -> {fn {_pid, info} -> info[:reductions] end, :desc}
        :pid -> {fn {pid, _info} -> pid end, :asc}
      end

    short_processes =
      processes
      |> Enum.map(fn p ->
        {p, Process.info(p, [:registered_name, :reductions, :status, :memory])}
      end)
      |> Enum.filter(fn {_p, info} -> info != nil end)
      |> Enum.sort_by(sort_value, direction)
      |> Enum.take(20)
      |> Enum.map(fn {pid, info} ->
        {pid, Keyword.put(info, :initial_call, initial_call(pid))}
      end)

    cpu = :cpu_sup.util([:per_cpu])

    %{
      cpu: cpu,
      cpu_average: cpu_average(cpu),
      memory: Map.new(:erlang.memory()),
      uptime: :wall_clock |> :erlang.statistics() |> elem(0),
      elixir: System.version(),
      otp: System.otp_release(),
      schedulers: %{
        online: System.schedulers_online(),
        total: System.schedulers()
      },
      process_count: length(processes),
      processes: short_processes
    }
  end

  def cpu_average([]), do: 0.0

  def cpu_average(cores) do
    Enum.reduce(cores, 0.0, fn {_id, busy, _idle, _misc}, total -> total + busy end) /
      length(cores)
  end

  @doc "Returns a readable entry point for an unregistered process, without exposing its dictionary."
  def initial_call(pid) do
    case Process.info(pid, [:initial_call, :dictionary]) do
      nil ->
        "exited"

      info ->
        call = Keyword.get(info[:dictionary], :"$initial_call", info[:initial_call])
        format_initial_call(call)
    end
  end

  defp format_initial_call({module, function, arity})
       when is_atom(module) and is_atom(function) and is_integer(arity) do
    "#{inspect(module)}.#{function}/#{arity}"
  end

  defp format_initial_call(_call), do: "unknown"
end
