defmodule HolodeckWeb.LogBroadcasterTest do
  use ExUnit.Case, async: false

  alias HolodeckWeb.LogBroadcaster

  @moduletag capture_log: true

  setup do
    original = Application.get_env(:holodeck, LogBroadcaster)
    {:ok, handler} = :logger.get_handler_config(LogBroadcaster)
    primary = :logger.get_primary_config()
    :logger.remove_handler(LogBroadcaster)
    Application.put_env(:holodeck, LogBroadcaster, min_level: :info)
    assert :ok = LogBroadcaster.attach()
    :logger.set_primary_config(:level, :debug)

    on_exit(fn ->
      :logger.remove_handler(LogBroadcaster)
      :logger.add_handler(LogBroadcaster, LogBroadcaster, Map.drop(handler, [:id, :module]))
      :logger.set_primary_config(:level, primary.level)

      if original do
        Application.put_env(:holodeck, LogBroadcaster, original)
      else
        Application.delete_env(:holodeck, LogBroadcaster)
      end
    end)

    Holodeck.HologramHelpers.ensure_pubsub_started()
    Phoenix.PubSub.subscribe(Hologram.PubSub, "hologram:channel:dashboard:logs")
    :ok
  end

  test "broadcasts only a plain string and minimal public metadata" do
    LogBroadcaster.log(
      %{
        level: :info,
        msg: {:string, ["\e[90mSELECT", [?\s, ?1], "\e[0m"]},
        meta: %{time: 1_234_567, mfa: {__MODULE__, :example, 0}, secret: "private", pid: self()}
      },
      %{}
    )

    assert_receive {:broadcast_action, {:dashboard, "logs"}, :logger, payload, []}

    assert payload == %{
             level: :info,
             msg: "SELECT 1",
             time: 1_234_567,
             module: "HolodeckWeb.LogBroadcasterTest"
           }
  end

  test "invalid UTF-8 is replaced without removing the installed handler" do
    :logger.log(:info, ["GET ", <<255>>])
    assert_receive {:broadcast_action, _, :logger, %{msg: message}, []}
    assert message == "GET �"
    assert String.valid?(message)
    assert {:ok, _} = :logger.get_handler_config(LogBroadcaster)

    :logger.log(:info, "still attached")
    assert_receive {:broadcast_action, _, :logger, %{msg: "still attached"}, []}
  end

  test "handles format and args messages in the worker" do
    LogBroadcaster.log(
      %{level: :info, msg: {~c"value: ~ts (~B)", ["\e[90mhello\e[0m", 42]}, meta: %{time: 42}},
      %{}
    )

    assert_receive {:broadcast_action, _, :logger, %{msg: "value: hello (42)"}, []}
  end

  test "strips OSC hyperlinks as well as colour codes and tolerates missing mfa" do
    LogBroadcaster.log(
      %{
        level: :warning,
        msg: {:string, "\e]8;;https://example.com\ahello\e]8;;\a"},
        meta: %{time: 42}
      },
      %{}
    )

    assert_receive {:broadcast_action, _, :logger, payload, []}
    assert payload == %{level: :warning, msg: "hello", time: 42, module: ""}
  end

  test "OTP filters below the configured minimum but includes the minimum and higher" do
    assert {:ok, %{level: :info}} = :logger.get_handler_config(LogBroadcaster)

    for level <- [:debug, :info, :notice, :warning, :error, :critical, :alert, :emergency] do
      :logger.log(level, "message")

      if level == :debug do
        refute_receive {:broadcast_action, _, :logger, _, []}
      else
        assert_receive {:broadcast_action, _, :logger, %{level: ^level}, []}
      end
    end
  end

  test "minimum level is read when attaching, not for every message" do
    Application.put_env(:holodeck, LogBroadcaster, min_level: :debug)
    :logger.log(:debug, "not yet")
    refute_receive {:broadcast_action, _, :logger, _, []}

    :logger.remove_handler(LogBroadcaster)
    assert :ok = LogBroadcaster.attach()
    :logger.log(:debug, "debug")
    assert_receive {:broadcast_action, _, :logger, %{level: :debug}, []}
  end

  test "drops Hologram request starts and stops but retains normal app traffic" do
    request(:start, "/hologram/command")
    request(:stop)
    refute_receive {:broadcast_action, _, :logger, _, []}

    request(:start, "/dashboard")
    assert_receive {:broadcast_action, _, :logger, %{msg: "POST /dashboard"}, []}
    request(:stop)
    assert_receive {:broadcast_action, _, :logger, %{msg: "Sent 200 in 1ms"}, []}

    :logger.log(:info, "internal", %{request_path: "/hologram/command"})
    refute_receive {:broadcast_action, _, :logger, _, []}
  end

  test "drops Bandit events, crash reports, and framework exception rendering" do
    :logger.set_handler_config(LogBroadcaster, :level, :debug)
    :logger.log(:error, "exception text", %{domain: [:bandit]})
    :logger.log(:error, "crash text", %{crash_reason: {:secret, []}})
    :logger.log(:debug, "debugger exception", %{mfa: {Plug.Debugger, :log, 4}})

    :logger.log(:info, "rendered exception", %{
      mfa: {Phoenix.Logger, :phoenix_error_rendered, 4}
    })

    refute_receive {:broadcast_action, _, :logger, _, []}
    :logger.log(:info, "ordinary application log")
    assert_receive {:broadcast_action, _, :logger, %{msg: "ordinary application log"}, []}
  end

  test "ignores non-string logger reports" do
    assert LogBroadcaster.log(%{level: :error, msg: {:report, %{}}, meta: %{}}, %{}) == :ok
    refute_receive {:broadcast_action, _, :logger, _, []}
  end

  defp request(:start, path) do
    :logger.log(:info, ["POST", ?\s, path], %{mfa: {Phoenix.Logger, :phoenix_endpoint_start, 4}})
  end

  defp request(:stop) do
    :logger.log(:info, ["Sent", ?\s, "200", " in ", "1ms"], %{
      mfa: {Phoenix.Logger, :phoenix_endpoint_stop, 4}
    })
  end
end
