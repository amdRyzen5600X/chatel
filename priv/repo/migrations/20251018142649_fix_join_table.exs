defmodule Chatel.Repo.Migrations.FixJoinTable do
  use Ecto.Migration

  def change do
    alter table(:conversation_participants) do
      remove :inserted_at
      remove :updated_at
    end
  end
end
