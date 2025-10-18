defmodule Chatel.Conversation.Message do
  use Ecto.Schema

  schema "messages" do
    field :text, Chatel.Encrypted.Binary
    belongs_to :sender_user, Chatel.Accounts.User, foreign_key: :sender_id
    belongs_to :conversation, Chatel.Conversation.Conversation

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> Ecto.Changeset.cast(attrs, [:text, :sender_id, :conversation_id])
    |> Ecto.Changeset.validate_required([:text, :sender_id, :conversation_id])
  end
end
