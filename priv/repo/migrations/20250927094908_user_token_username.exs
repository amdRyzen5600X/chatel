defmodule Chatel.Repo.Migrations.UserTokenUsername do
  use Ecto.Migration

  def change do
    alter table(:users_tokens) do
      add :username, :string
    end
  end
end
