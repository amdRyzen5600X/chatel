defmodule Chatel.Repo.Migrations.CleanTables do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      remove :recipient_user_id
      remove :sender_user_id

      add :sender_id, references(:users, on_delete: :nilify_all)
      add :conversation_id, references(:conversations, on_delete: :nilify_all)
    end
  end
end
