defmodule Holodeck.Kanban.Card do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "kanban_cards" do
    field :board_id, :string
    field :title, :string
    field :column, :string
    field :position, :integer
    field :version, :integer, default: 1
    timestamps(type: :utc_datetime_usec)
  end
end
