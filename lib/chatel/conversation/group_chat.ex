defmodule Chatel.Conversation.GroupChat do
  alias Ecto.Repo
  alias Chatel.Accounts.User
  alias Ecto.Repo
  alias Chatel.Conversation.GroupChat
  alias Chatel.Repo
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset

  schema "group_chats" do
    field :display_name, :string
    field :chat_name, :string
    many_to_many :users, Chatel.Accounts.User, join_through: "group_chats_users"
    belongs_to :owner, Chatel.Accounts.User
    has_many :messages, Chatel.Conversation.ChatMessage

    field :last_message, :map, virtual: true

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(group_chat, attrs) do
    users =
      from u in User,
        where: u.id in ^attrs[:user_ids],
        select: u

    users = Repo.all(users)

    group_chat
    |> cast(attrs, [:display_name, :chat_name, :owner_id])
    |> validate_required([:display_name, :chat_name, :owner_id])
    |> put_assoc(:users, users)
  end

  def change_chat_name_changeset(group_chat, attrs) do
    group_chat
    |> cast(attrs, [:chat_name])
    |> case do
      %{changes: %{chat_name: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :chat_name, "did not change")
    end
    |> validate_required([:chat_name])
  end

  def change_display_name_changeset(group_chat, attrs) do
    group_chat
    |> cast(attrs, [:display_name])
    |> case do
      %{changes: %{display_name: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :display_name, "did not change")
    end
    |> validate_required([:display_name])
  end

  def add_users_changeset(group_chat, attrs) do
    if length(attrs[:user_ids]) <= 0 do
      add_error(group_chat, :user_ids, "must have at least one user")
    else
      users =
        from u in User,
          where: u.id in ^attrs[:user_ids],
          select: u

      users = Repo.all(users)

      group_chat
      |> put_assoc(:users, users)
    end
  end

  def list_group_chats(user_id) do
    Repo.all(GroupChat)
    |> Repo.preload(:users)
    |> Enum.filter(fn group_chat ->
      user_id in Enum.map(group_chat.users, fn usr -> usr.id end)
    end)
  end
end
