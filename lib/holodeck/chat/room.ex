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
    |> unique_constraint(:name, message: "A room with this name already exists")
  end

  def validate_name(changeset) do
    changeset
    |> update_change(:name, &String.trim/1)
    |> validate_required(:name, message: "Room name can't be blank")
    |> validate_length(:name,
      min: 3,
      max: 40,
      count: :codepoints,
      message: "Room names must be 3–40 characters"
    )
    |> validate_format(:name, ~r/^[\p{L}\p{N}_-]+$/u,
      message: "Room names can only contain letters, numbers, dashes and underscores"
    )
  end

  def validate_creator(changeset) do
    changeset
    |> validate_required(:creator, message: "Username can't be blank")
    |> validate_length(:creator,
      max: 32,
      count: :codepoints,
      message: "Usernames can be at most 32 characters"
    )
  end
end
