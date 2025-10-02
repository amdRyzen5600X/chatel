defmodule Chatel.Repo.Migrations.FixRepation do
  use Ecto.Migration

  def change do
    rename table(:messages), :sender_id, to: :user_id
  end
end
