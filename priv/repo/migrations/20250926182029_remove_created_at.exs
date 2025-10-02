defmodule Chatel.Repo.Migrations.RemoveCreatedAt do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      remove :created_at
    end
  end
end
