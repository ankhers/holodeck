defmodule Holodeck.Kanban.Board do
  use Ecto.Schema

  @primary_key {:id, :string, autogenerate: false}
  schema "kanban_boards" do
    field :revision, :integer, default: 0
    field :next_position, :integer, default: 7
    field :last_reset_at, :utc_datetime_usec
  end
end
