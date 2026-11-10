defmodule HolodeckWeb.ChangesetErrors do
  @moduledoc false

  def message(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.flat_map(fn {_field, errors} -> errors end)
    |> Enum.join(", ")
  end
end
