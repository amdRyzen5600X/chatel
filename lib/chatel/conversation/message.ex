defmodule Chatel.Conversation.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :text, :string
    belongs_to :sender_user, Chatel.Accounts.User
    belongs_to :recipient_user, Chatel.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:text, :sender_user_id, :recipient_user_id])
    |> validate_required([:text, :sender_user_id, :recipient_user_id])
  end
end
