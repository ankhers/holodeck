defmodule Holodeck.Polls.Poll do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "polls" do
    field :question, :string
    field :answer_1, :string
    field :answer_2, :string
    field :answer_3, :string
    field :answer_4, :string

    timestamps()
  end

  def create_changeset(poll, params) do
    poll
    |> cast(params, [:question, :answer_1, :answer_2, :answer_3, :answer_4])
    |> validate_question()
    |> validate_answer(:answer_1)
    |> validate_answer(:answer_2)
    |> validate_answer(:answer_3)
    |> validate_answer(:answer_4)
  end

  defp validate_question(changeset) do
    validate_required(changeset, :question)
  end

  defp validate_answer(changeset, field) do
    validate_required(changeset, field)
  end
end
