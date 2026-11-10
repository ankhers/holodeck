# Holodeck

A showcase application for the [Hologram](https://hologram.page) framework. Each
of its mini-apps is built to demonstrate a different aspect of Hologram,
particularly its real-time features, running inside a single Phoenix project.

Holodeck favours showing off Hologram over production boilerplate. A few
shortcuts were taken deliberately (for example, there is no real authentication,
a chat "username" is just a string kept in the session) so the focus stays on the
framework rather than the scaffolding around it.

## Stack

- **[Hologram](https://hologram.page)** - the framework being showcased. Pages
  are written as Hologram pages/components and declare their own routes via the
  `route` macro; state lives on the client, where `action`s run exclusively to
  update component state, while `command`s run on the server. Real-time updates
  flow through `Hologram.Realtime` subscriptions and broadcasts.
- **Phoenix / Bandit** - HTTP endpoint.
- **Ecto + PostgreSQL** - persistence for chat rooms, messages, and polls.
- **Tailwind CSS** - stylesheet pipeline; Hologram builds its own JavaScript bundles.

## Getting started

Hologram 0.12 requires Elixir 1.19+, OTP 28.1+, and Node.js 20+ (with npm).
The devenv shell provides the supported toolchain.

```sh
mix setup          # install deps, create + migrate DB, build assets
mix holo           # or: iex -S mix holo
```

Then visit [`localhost:4000`](http://localhost:4000). The home page links to each
of the three apps.

A Postgres database is required; connection settings live in `config/dev.exs`.

## The apps

All three apps use Hologram's real-time capabilities, server-side `command`s
broadcast `action`s to every subscribed client, so each browser updates live
without a page reload.

### Chat — `/chat`

Real-time messaging across multiple rooms.

- Users assign themselves a display name, which is stored in the session
  (`holodeck_chat_username`).
- From the lobby (`/chat`) you can see existing rooms and create new ones.
- Inside a room (`/chat/:room_name`), joining fetches the room's full message
  history from the database.
- New messages are persisted and then broadcast over a `{:chat_room, name}`
  subscription, so every connected member sees them instantly. Usernames are
  given a stable colour derived from their first character.

### Dashboard — `/dashboard`

A live view into the running BEAM/system.

- Shows CPU utilisation (per core), memory breakdown, uptime, scheduler counts,
  Elixir/OTP versions, and the top 20 processes, sortable by memory, reductions,
  or pid (the chosen sort is remembered in the session).
- Metrics refresh on a recurring server `tick` (every 5s) via a self-rescheduling
  action.
- **Log streaming:** `HolodeckWeb.LogBroadcaster` is installed as an Erlang
  `:logger` handler. Non-Hologram request logs and application string/format logs
  at or above the configured minimum level (`:debug` in dev, `:info` in prod) are
  broadcast over `{:dashboard, "logs"}`. The page retains the newest 100 entries.
  Each entry contains only level, time, module name, and an ANSI-stripped, valid
  UTF-8 message. Logger metadata, Hologram internal request traffic, structured
  reports, Bandit events, Plug/Phoenix exception-rendering events (exception text
  and stack traces), and any event carrying `crash_reason` are not broadcast. This is still a public feed: arbitrary
  application message text is not secret-redacted, so do not log secrets or manually
  formatted exceptions containing user data at broadcast levels.

### Polls — `/poll`

Create, vote on, and watch the results of simple polls.

- Create a poll (`/poll`) with a question and four answers; polls are stored in
  Postgres with a UUID primary key.
- Vote at `/poll/:poll_id/vote`, submitting a vote records a result and redirects
  to the results page.
- Results at `/poll/:poll_id` render a live bar chart. This page also showcases
  Hologram's **JavaScript interop** (`Hologram.JS`) by importing and driving
  [Chart.js](https://www.chartjs.org/) directly, votes are pushed into a shared
  `Float64Array` buffer and the chart is updated in place.
- Each new vote is broadcast over a `{:poll_result, poll_id}` subscription, so
  anyone watching the results sees the chart move as votes come in.

## Project layout

```
lib/holodeck/            Contexts + Ecto schemas (chat, dashboard, polls)
lib/holodeck_web/pages/  Hologram pages, grouped by app (chat, dashboard, poll)
lib/holodeck_web/        Endpoint, router, components, log broadcaster
config/                  Environment configuration
```

## Development

```sh
mix precommit   # compile (warnings as errors), unlock unused deps, format, test
```

### Browser tests

`mix test` and `mix precommit` exclude tests tagged `:e2e`. Run the two-session
chat and poll features explicitly in headless Chrome from the devenv shell:

```sh
E2E=1 PORT=4402 MIX_TEST_PARTITION=_e2e mix test test/e2e --include e2e
```

Use `direnv exec .` before the command if outside the shell. PostgreSQL must be
running; set `PGHOST` to its socket directory if it is not already in your
environment. The partition isolates the browser suite's database, and `PORT`
avoids the development/test servers on shared machines (choose another free port
if 4402 is occupied). No separate application server is needed.

`E2E=1` enables the test endpoint and calls the public `Hologram.Test.setup()` to
compile browser assets and start Hologram. Wallaby and the matching Chromium /
chromedriver pair from `devenv.nix` are only started for this opt-in run. Tests
use shared SQL sandbox ownership, run serially, and roll back their fixtures.
Repo-local browser helpers wait for Hologram's mounted page and WebSocket/SSE
connections using Wallaby retries, then assertions use Wallaby's built-in waiting.
The unit-test PubSub helper reuses Hologram's PubSub when it is already running.
