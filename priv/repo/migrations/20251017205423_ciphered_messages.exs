defmodule Chatel.Repo.Migrations.CipheredMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      remove :text
      add :text, :binary
    end
  end
end
