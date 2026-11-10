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
    expected_page = inspect(page)

    result =
      retry(fn ->
        execute_script(
          session,
          """
          return {
            mountedPage: globalThis.Hologram?.mountedPage ?? null,
            wsConnected: globalThis.Hologram?.['wsConnected?'] ?? null,
            sseConnected: globalThis.Hologram?.['sseConnected?'] ?? null
          };
          """,
          [],
          fn state -> send(self(), {:page_state, state}) end
        )

        receive do
          {:page_state,
           %{"mountedPage" => mounted_page, "wsConnected" => true, "sseConnected" => true}}
          when mounted_page == expected_page ->
            {:ok, session}

          {:page_state, state} ->
            {:error, state}
        end
      end)

    assert {:ok, ^session} = result,
           "Hologram page or connections did not become ready for #{inspect(page)}: #{inspect(result)}"

    session
  end
end
