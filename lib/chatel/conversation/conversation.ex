defmodule Chatel.Conversation.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  @conversation_group_chat "group"
  @conversation_dm "direct"

  schema "conversations" do
    field :type, :string
    field :group_name, :string
    belongs_to :owner, Chatel.Accounts.User

    field :last_message, :map, virtual: true


    has_many :messages, Chatel.Conversation.Message

    many_to_many :participants, Chatel.Accounts.User,
      join_through: "conversation_participants",
      on_replace: :delete

    timestamps()
  end

  def changeset(conversation, attrs) do
    case attrs[:type] do
      @conversation_group_chat ->
        conversation
        |> cast(attrs, [:group_name, :type, :owner_id])
        |> put_assoc(:participants, attrs.participants)
        |> validate_required([:group_name, :type, :owner_id])

      @conversation_dm ->
        conversation
        |> cast(attrs, [:type])
        |> put_assoc(:participants, attrs.participants)
        |> validate_required([:type])

      _ ->
        conversation
        |> add_error(
          :type,
          "type can only be one of [#{@conversation_dm}, {@conversation_group_chat}]"
        )
    end
  end

  def change_conversation_group_name_changeset(conversation, attrs) do
    if conversation.type == "direct" do
      conversation
      |> add_error(:type, "can't change group_name for direct conversation")
    else
      conversation
      |> cast(attrs, [:group_name])
      |> case do
        %{changes: %{group_name: _}} = changeset -> changeset
        %{} = changeset -> add_error(changeset, :group_name, "did not change")
      end
      |> validate_required([:group_name])
    end
  end

  def add_users_changeset(conversation, attrs) do
    if conversation.type == "direct" do
      conversation
      |> add_error(:type, "can't add users to direct conversation")
    else
      conversation
      |> put_assoc(:participants, attrs.participants)
    end
  end
end
