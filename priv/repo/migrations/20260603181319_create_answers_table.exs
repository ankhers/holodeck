defmodule Holodeck.Repo.Migrations.CreateAnswersTable do
  use Ecto.Migration

  def change do
    create table(:poll_answers, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :answer_number, :integer, null: false

      add :poll_id, references(:polls, type: :binary_id), null: false

      timestamps()
    end

    create index(:poll_answers, [:poll_id])
  end
end
