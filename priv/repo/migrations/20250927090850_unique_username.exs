defmodule Chatel.Repo.Migrations.UniqueUsername do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :username
    end

    alter table(:users) do
      add :username, :string, unique: true, null: false
    end

    create unique_index(:users, [:username])
  end
end
