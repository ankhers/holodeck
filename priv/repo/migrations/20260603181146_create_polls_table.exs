defmodule Holodeck.Repo.Migrations.CreatePollsTable do
  use Ecto.Migration

  def change do
    create table(:polls, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :question, :string, null: false

      add :answer_1, :string, null: false
      add :answer_2, :string, null: false
      add :answer_3, :string, null: false
      add :answer_4, :string, null: false

      timestamps()
    end
  end
end
