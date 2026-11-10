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
- **Tailwind CSS + esbuild** - asset pipeline.

## Getting started

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
  `:logger` handler. String log messages at or above the configured minimum level
  (`:debug` in dev, `:info` in prod) are broadcast over `{:dashboard, "logs"}`.
  The page retains the newest 100 entries, colour-coded by level. Broadcasts contain
  only level, ANSI-stripped message, timestamp, and module name—not arbitrary logger
  metadata. This is still a public log feed: message text is not redacted and may
  contain sensitive information, so avoid logging secrets at broadcast levels.

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
