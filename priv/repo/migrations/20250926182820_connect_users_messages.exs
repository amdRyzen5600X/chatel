defmodule Chatel.Repo.Migrations.ConnectUsersMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      remove :text
    end

    alter table(:messages) do
      add :text, :text
      add :sender_id, references(:users, on_delete: :delete_all), null: false
    end

  end
end
