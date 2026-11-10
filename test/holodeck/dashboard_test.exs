defmodule Holodeck.DashboardTest do
  use ExUnit.Case, async: true

  alias Holodeck.Dashboard

  test "CPU average handles idle samples and many cores" do
    assert Dashboard.cpu_average([]) == 0.0
    cores = Enum.map(1..32, &{&1, 25.0, 75.0, []})
    assert Dashboard.cpu_average(cores) == 25.0
    assert Dashboard.cpu_average([{0, 10.0, 90.0, []}, {1, 70.0, 30.0, []}]) == 40.0
  end

  def initial_state, do: :ready

  test "unregistered OTP processes show their actual initial call" do
    pid =
      start_supervised!(%{
        id: :initial_call_agent,
        start: {Agent, :start_link, [__MODULE__, :initial_state, []]}
      })

    assert Process.info(pid, :registered_name) == {:registered_name, []}
    assert Dashboard.initial_call(pid) == "Holodeck.DashboardTest.initial_state/0"
  end

  test "plain processes fall back to Process.info initial call" do
    assert Dashboard.initial_call(self()) =~ ~r/.+\..+\/\d+$/
  end

  test "exited processes have a safe fallback" do
    pid = start_supervised!({Agent, fn -> :ready end})
    ref = Process.monitor(pid)
    :ok = stop_supervised(Agent)
    assert_receive {:DOWN, ^ref, :process, ^pid, :shutdown}
    assert Dashboard.initial_call(pid) == "exited"
  end

  test "pid sort uses ascending pid order" do
    processes = Dashboard.system_metrics(process_sort: :pid).processes
    pids = Enum.map(processes, &elem(&1, 0))

    assert length(pids) == 20
    assert Enum.all?(processes, fn {_pid, info} -> is_binary(info[:initial_call]) end)
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
