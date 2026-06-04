defmodule Holodeck.Chat.Room do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "rooms" do
    field :name, :string
    field :creator, :string

    timestamps()
  end

  def create_changeset(room, params) do
    room
    |> cast(params, [:name, :creator])
    |> validate_name()
    |> validate_creator()
  end

  def validate_name(changeset) do
    changeset
    |> validate_required(:name, message: "Room name can't be blank")
    |> validate_length(:name, min: 3)
  end

  def validate_creator(changeset) do
    validate_required(changeset, :creator, message: "Username can't be blank")
  end
end
