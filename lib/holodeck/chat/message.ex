defmodule Holodeck.Chat.Message do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "messages" do
    field :username, :string
    field :message, :string

    belongs_to :room, Holodeck.Chat.Room

    timestamps()
  end

  def create_changeset(room, params) do
    room
    |> cast(params, [:username, :message, :room_id])
    |> validate_username()
    |> validate_message()
    |> validate_room()
  end

  defp validate_username(changeset) do
    validate_required(changeset, :username)
  end

  defp validate_message(changeset) do
    validate_required(changeset, :message)
  end

  defp validate_room(changeset) do
    validate_required(changeset, :room_id)
  end
end
