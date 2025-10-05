defmodule Chatel.Repo.Migrations.GroupChats do
  use Ecto.Migration

  def change do
    create table(:group_chats) do
      add :display_name, :string, null: false
      add :chat_name, :string, null: false, unique: true
      add :owner_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create table(:group_chats_users) do
      add :group_chat_id, references(:group_chats, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:group_chats_users, [:group_chat_id, :user_id])

    create table(:chat_messages) do
      add :text, :string
      add :sender_user_id, references(:users, on_delete: :nothing)
      add :group_chat_id, references(:group_chats, on_delete: :nothing)

      timestamps()
    end
  end
end
