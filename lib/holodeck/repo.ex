defmodule Holodeck.Repo do
  use Ecto.Repo,
    otp_app: :holodeck,
    adapter: Ecto.Adapters.Postgres
end
