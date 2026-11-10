defmodule Holodeck.DashboardTest do
  use ExUnit.Case, async: true

  alias Holodeck.Dashboard

  test "pid sort uses ascending pid order" do
    processes = Dashboard.system_metrics(process_sort: :pid).processes
    pids = Enum.map(processes, &elem(&1, 0))

    assert length(pids) == 20
    assert pids == Enum.sort(pids)
  end

  test "memory is reported in bytes and sorted descending" do
    processes = Dashboard.system_metrics(process_sort: :memory).processes
    memory = Enum.map(processes, fn {_pid, info} -> Keyword.fetch!(info, :memory) end)

    assert Enum.all?(memory, &(is_integer(&1) and &1 > 0))
    assert memory == Enum.sort(memory, :desc)
  end

  test "reductions sort stays descending" do
    processes = Dashboard.system_metrics(process_sort: :reductions).processes
    reductions = Enum.map(processes, fn {_pid, info} -> info[:reductions] end)

    assert reductions == Enum.sort(reductions, :desc)
  end
end
