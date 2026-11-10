defmodule HolodeckWeb.LogBroadcasterTest do
  use ExUnit.Case, async: false

  alias HolodeckWeb.LogBroadcaster

  setup do
    original = Application.get_env(:holodeck, LogBroadcaster)
    Application.put_env(:holodeck, LogBroadcaster, min_level: :info)

    on_exit(fn ->
      if original do
        Application.put_env(:holodeck, LogBroadcaster, original)
      else
        Application.delete_env(:holodeck, LogBroadcaster)
      end
    end)

    start_supervised!({Phoenix.PubSub, name: Hologram.PubSub})
    Phoenix.PubSub.subscribe(Hologram.PubSub, "hologram:channel:dashboard:logs")
    :ok
  end

  test "broadcasts only a plain string and minimal public metadata" do
    event = %{
      level: :info,
      msg: {:string, ["\e[90mSELECT", [?\s, ?1], "\e[0m"]},
      meta: %{time: 1_234_567, mfa: {__MODULE__, :example, 0}, secret: "private", pid: self()}
    }

    LogBroadcaster.log(event, %{})

    assert_receive {:broadcast_action, {:dashboard, "logs"}, :logger, payload, []}

    assert payload == %{
             level: :info,
             msg: "SELECT 1",
             time: 1_234_567,
             module: "HolodeckWeb.LogBroadcasterTest"
           }
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

  test "filters below the configured minimum but includes the minimum and higher" do
    for level <- [:debug, :info, :notice, :warning, :error, :critical, :alert, :emergency] do
      LogBroadcaster.log(%{level: level, msg: {:string, "message"}, meta: %{time: 42}}, %{})

      if level == :debug do
        refute_receive {:broadcast_action, _, :logger, _, []}
      else
        assert_receive {:broadcast_action, _, :logger, %{level: ^level}, []}
      end
    end
  end

  test "minimum level can be configured to debug" do
    Application.put_env(:holodeck, LogBroadcaster, min_level: :debug)
    LogBroadcaster.log(%{level: :debug, msg: {:string, "debug"}, meta: %{time: 42}}, %{})
    assert_receive {:broadcast_action, _, :logger, %{level: :debug}, []}
  end

  test "ignores non-string logger reports" do
    assert LogBroadcaster.log(%{level: :error, msg: {:report, %{}}, meta: %{}}, %{}) == :ok
    refute_receive {:broadcast_action, _, :logger, _, []}
  end
end
