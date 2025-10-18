defmodule Chatel.Repo.Migrations.AddMissingIndexes do
  use Ecto.Migration

  def change do
    create index(:messages, [:sender_user_id])
    create index(:messages, [:recipient_user_id])

    create index(:chat_messages, [:sender_user_id])
    create index(:chat_messages, [:group_chat_id])
  end
end
