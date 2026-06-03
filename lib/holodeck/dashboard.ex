defmodule Holodeck.Dashboard do
  def system_metrics(opts) do
    process_sort = Keyword.get(opts, :process_sort, :memory)

    processes = Process.list()

    sort_key =
      case process_sort do
        :memory -> :total_heap_size
        :reductions -> :reductions
        :pid -> :total_heap_size
      end

    short_processes =
      processes
      |> Enum.map(fn p -> {p, Process.info(p)} end)
      |> Enum.filter(fn {_p, info} -> info != nil end)
      |> Enum.sort_by(fn {_p, info} -> info[sort_key] end, :desc)
      |> Enum.take(20)

    %{
      cpu: :cpu_sup.util([:per_cpu]),
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
end
