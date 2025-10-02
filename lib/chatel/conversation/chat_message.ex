defmodule Chatel.Conversation.ChatMessage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "chat_messages" do
    field :text, :string
    belongs_to :sender_user, Chatel.Accounts.User
    belongs_to :group_chat, Chatel.Conversation.GroupChat

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:text, :sender_user_id, :group_chat_id])
    |> validate_required([:text, :sender_user_id, :group_chat_id])
  end
end
