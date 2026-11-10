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
    |> assoc_constraint(:room)
  end

  defp validate_username(changeset) do
    changeset
    |> validate_required(:username)
    |> validate_length(:username,
      max: 32,
      count: :codepoints,
      message: "Usernames can be at most 32 characters"
    )
  end

  defp validate_message(changeset) do
    changeset
    |> validate_required(:message)
    |> validate_length(:message,
      max: 255,
      count: :codepoints,
      message: "Messages can be at most 255 characters"
    )
  end

  defp validate_room(changeset) do
    validate_required(changeset, :room_id)
  end
end
