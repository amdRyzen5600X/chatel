defmodule Chatel.Repo.Migrations.Cleanup do
  use Ecto.Migration

  def change do
    drop table(:group_chats_users)
    drop table(:chat_messages)
    drop table(:group_chats)
  end
end
