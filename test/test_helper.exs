e2e? = System.get_env("E2E") == "1"
ExUnit.start(exclude: if(e2e?, do: [], else: [:e2e]))
Ecto.Adapters.SQL.Sandbox.mode(Holodeck.Repo, :manual)

if e2e? do
  Mix.Task.run("assets.build")
  {:ok, _} = Hologram.Test.setup()
  Application.put_env(:wallaby, :driver, Wallaby.Chrome)
  port = HolodeckWeb.Endpoint.config(:http)[:port]
  Application.put_env(:wallaby, :base_url, "http://127.0.0.1:#{port}")
  Application.put_env(:wallaby, :max_wait_time, 10_000)
  Application.put_env(:wallaby, :chromedriver, binary: System.find_executable("chromium"))
  {:ok, _} = Application.ensure_all_started(:wallaby)
end
