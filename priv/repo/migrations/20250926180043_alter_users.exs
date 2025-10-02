defmodule Chatel.Repo.Migrations.AlterUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :username, :string
      add :is_admin, :boolean, default: false
    end
  end
end
