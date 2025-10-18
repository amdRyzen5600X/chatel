defmodule Chatel.Repo.Migrations.CreateConversation do
  use Ecto.Migration

  def change do
    create table(:conversations) do
      add :type, :string, null: false
      add :group_name, :string, null: true
      add :owner_id, references(:users, on_delete: :nilify_all)

      timestamps()
    end

    create table(:conversation_participants) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :conversation_id, references(:conversations, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:conversation_participants, [:user_id, :conversation_id])
  end
end
