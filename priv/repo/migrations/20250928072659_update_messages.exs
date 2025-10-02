defmodule Chatel.Repo.Migrations.UpdateMessages do
  use Ecto.Migration

  def change do
    rename table(:messages), :user_id, to: :sender_user_id

    alter table(:messages) do
      add :recipient_user_id, references(:users, on_delete: :delete_all)
    end
  end
end
