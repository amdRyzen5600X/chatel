defmodule Chatel.Repo.Migrations.AlterJoinTable do
  use Ecto.Migration

  def change do
    alter table(:group_chats_users) do
      remove :inserted_at
      remove :updated_at
    end
  end
end
