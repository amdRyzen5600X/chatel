defmodule Chatel.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :text, :string
      add :created_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end
  end
end
