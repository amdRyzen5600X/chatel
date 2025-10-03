defmodule ChatelWeb.CreateChatModal do
  alias ChatelWeb.CoreComponents
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <div phx-target={@myself} id="create-chat-modal-component">
      <%= if @show_modal do %>
        <div
          id="new-chat-modal"
          class="fixed inset-0 bg-black bg-opacity-60 z-50 flex justify-center items-center"
        >
          <div
            class="bg-white dark:bg-gray-900 rounded-lg shadow-xl p-6 w-full max-w-md"
            phx-click.stop
          >
            <h3 class="text-xl font-bold mb-4 text-gray-900 dark:text-white">
              Create New Group Chat
            </h3>

            <CoreComponents.simple_form for={@chat_form} phx-submit="save_chat" phx-target={@myself}>
              <CoreComponents.input
                field={@chat_form[:name]}
                type="text"
                label="Chat Name"
                required="true"
              />

              <div class="mt-4">
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                  Add Users
                </label>
                <div class="mt-2 max-h-48 overflow-y-auto rounded-md border border-gray-300 dark:border-gray-600 p-2 space-y-2">
                  <%= for user <- @all_users do %>
                    <label class="flex items-center space-x-3 p-1 rounded-md hover:bg-gray-50 dark:hover:bg-gray-800">
                      <input
                        type="checkbox"
                        name="chat[user_ids][]"
                        value={user.id}
                        class="h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                      />
                      <span class="text-gray-900 dark:text-white">{user.username}</span>
                    </label>
                  <% end %>
                </div>
              </div>

              <:actions>
                <CoreComponents.button
                  type="button"
                  phx-click="close_modal"
                  class="bg-gray-200 dark:bg-gray-700 hover:bg-gray-300 dark:hover:bg-gray-600 text-gray-800 dark:text-gray-200"
                  phx-target={@myself}
                >
                  Cancel
                </CoreComponents.button>
                <CoreComponents.button
                  phx-disable-with="Saving..."
                  class="bg-indigo-500 hover:bg-indigo-700 text-white"
                  phx-target={@myself}
                >
                  Create Chat
                </CoreComponents.button>
              </:actions>
            </CoreComponents.simple_form>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("create-chat", _params, socket) do
    {:noreply, assign(socket, :show_modal, true)}
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, :show_modal, false)}
  end

  def handle_event("save_chat", %{"chat" => %{"user_ids" => user_ids}, "name" => name}, socket) do
    user_ids = Enum.map(user_ids, &String.to_integer/1)
    all_users_for_chat = [socket.assigns.current_user.id | user_ids] |> Enum.uniq()

    case Chatel.Chat.create_group_chat(
           name,
           name,
           all_users_for_chat,
           socket.assigns.current_user.id
         ) do
      {:ok, _group_chat} ->
        send(socket.assigns.parent, :chat_created)
        {:noreply, assign(socket, :show_modal, false)}

      {:error, changeset} ->
        {:noreply, assign(socket, chat_form: to_form(changeset))}
    end
  end

  def handle_event("save_chat", %{"chat" => %{"name" => name}}, socket) do
    current_user_id = socket.assigns.current_user.id

    case Chatel.Chat.create_group_chat(name, name, [current_user_id], current_user_id) do
      {:ok, _group_chat} ->
        send(socket.assigns.parent, :chat_created)
        {:noreply, assign(socket, :show_modal, false)}

      {:error, changeset} ->
        {:noreply, assign(socket, chat_form: to_form(changeset))}
    end
  end
end
