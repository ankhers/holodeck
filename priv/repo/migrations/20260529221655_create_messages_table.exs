defmodule Holodeck.Repo.Migrations.CreateMessagesTable do
  use Ecto.Migration

  def change do
    create table(:messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :username, :string, null: false
      add :message, :string, null: false
      add :room_id, references(:rooms, type: :binary_id)

      timestamps()
    end

    create index(:messages, [:room_id])
  end
end
