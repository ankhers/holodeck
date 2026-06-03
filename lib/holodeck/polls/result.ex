defmodule Holodeck.Polls.Result do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "poll_answers" do
    field :answer_number, :integer

    belongs_to :poll, Holodeck.Polls.Poll

    timestamps()
  end

  def create_changeset(result, params) do
    result
    |> cast(params, [:answer_number])
    |> validate_answer_number()
  end

  defp validate_answer_number(changeset) do
    changeset
    |> validate_required(:answer_number)
    |> validate_number(:answer_number, greater_than_or_equal_to: 1, less_than_or_equal_to: 4)
  end
end
