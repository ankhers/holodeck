defmodule Holodeck.BrowserHelpers do
  import ExUnit.Assertions
  import Wallaby.Browser

  # Wait for the runtime, not just SSR markup: both transports must be ready
  # before interacting or expecting a broadcast in this session.
  def visit_page(session, page, params \\ []) do
    session
    |> visit(Hologram.Router.Helpers.page_path(page, params))
    |> assert_page_ready(page)
  end

  def assert_page_ready(session, page) do
    result =
      retry(fn ->
        execute_script(
          session,
          """
          return globalThis.Hologram?.mountedPage === arguments[0] &&
            globalThis.Hologram?.['wsConnected?'] === true &&
            globalThis.Hologram?.['sseConnected?'] === true;
          """,
          [inspect(page)],
          fn ready? -> send(self(), {:page_ready, ready?}) end
        )

        receive do
          {:page_ready, true} -> {:ok, session}
          {:page_ready, _} -> {:error, :page_not_ready}
        end
      end)

    assert {:ok, ^session} = result, "Hologram page or connections did not become ready"
    session
  end
end
