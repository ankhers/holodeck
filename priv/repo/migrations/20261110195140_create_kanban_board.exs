defmodule Holodeck.Repo.Migrations.CreateKanbanBoard do
  use Ecto.Migration

  def up do
    create table(:kanban_boards, primary_key: false) do
      add :id, :string, primary_key: true
      add :revision, :bigint, null: false, default: 0
      add :next_position, :bigint, null: false, default: 7
      add :last_reset_at, :utc_datetime_usec
    end

    create table(:kanban_cards, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :board_id, references(:kanban_boards, type: :string), null: false
      add :title, :string, null: false
      add :column, :string, null: false
      add :position, :bigint, null: false
      add :version, :integer, null: false, default: 1
      timestamps(type: :utc_datetime_usec)
    end

    create constraint(:kanban_boards, :public_board, check: "id = 'public'")

    create constraint(:kanban_cards, :valid_column,
             check: "\"column\" IN ('todo', 'doing', 'done')"
           )

    create constraint(:kanban_cards, :valid_title,
             check: "char_length(title) BETWEEN 1 AND 120 AND title = btrim(title)"
           )

    create index(:kanban_cards, [:board_id, :column, :position])

    execute "INSERT INTO kanban_boards (id) VALUES ('public')"

    for {title, column, position} <- [
          {"Explore Hologram", "todo", 1},
          {"Try a targeted action", "todo", 2},
          {"Move a card", "doing", 3},
          {"Open another browser", "doing", 4},
          {"Build something together", "done", 5},
          {"Celebrate the small wins", "done", 6}
        ] do
      execute "INSERT INTO kanban_cards (id, board_id, title, \"column\", position, inserted_at, updated_at) VALUES ('#{Ecto.UUID.generate()}', 'public', '#{title}', '#{column}', #{position}, NOW(), NOW())"
    end
  end

  def down do
    drop table(:kanban_cards)
    drop table(:kanban_boards)
  end
end
