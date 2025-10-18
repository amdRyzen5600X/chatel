defmodule ChatelWeb.MessageComponent do
  alias Chatel.Chat
  use ChatelWeb, :live_component

  def render(assigns) do
    ~H"""
    <div
      id={"message-#{@message.id}"}
      class="relative"
      phx-target={@myself}
      phx-click-away={JS.hide(to: "#dropdown-#{@message.id}")}
    >
      <div class={@wrapper_class}>
        <div class={"p-3 rounded-lg max-w-md #{@bubble_class}"}>
          <%= if @current_chat.group_chat? && !@is_current_user? do %>
            <p class="text-m text-white">{@message.sender_user.username}</p>
          <% end %>
          <div class="flex items-end justify-between">
            <p class="text-xs break-words text-white">{@message.text}</p>
          </div>
        </div>

        <div class="p-2 cursor-pointer" phx-click={JS.toggle(to: "#dropdown-#{@message.id}")}>
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="currentColor"
            class="w-6 h-6"
          >
            <path
              fill-rule="evenodd"
              d="M10.5 6a1.5 1.5 0 113 0 1.5 1.5 0 01-3 0zm0 6a1.5 1.5 0 113 0 1.5 1.5 0 01-3 0zm0 6a1.5 1.5 0 113 0 1.5 1.5 0 01-3 0z"
              clip-rule="evenodd"
            />
          </svg>
        </div>
      </div>

      <div
        id={"dropdown-#{@message.id}"}
        class="absolute z-50 mt-2 rounded-md shadow-lg hidden right-0"
        style="min-width: 100px;"
      >
        <div class="rounded-md bg-white shadow-xs dark:bg-black">
          <div class="py-1">
            <button class="block w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-700 dark:text-gray-200">
              Edit
            </button>
            <button
              phx-click={
                JS.hide(to: "#dropdown-#{@message.id}")
                |> JS.push("delete-message", value: %{id: @message.id})
              }
              class="block w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-700 dark:text-gray-200"
            >
              Delete
            </button>
            <button
              phx-click="pin-message"
              phx-value-id={@message.id}
              phx-target={@myself}
              class="block w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-700 dark:text-gray-200"
            >
              Pin
            </button>
            <button
              phx-click="copy-message"
              phx-value-id={@message.id}
              phx-target={@myself}
              class="block w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-700 dark:text-gray-200 "
            >
              Copy
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def update(assigns, socket) do
    is_current_user? = assigns.current_user.id == assigns.message.sender_id

    wrapper_class =
      if is_current_user?, do: "flex justify-end", else: "flex justify-start"

    bubble_class =
      if is_current_user?, do: "bg-gray-100 dark:bg-blue-500", else: "bg-white dark:bg-gray-900"

    socket =
      socket
      |> assign(assigns)
      |> assign(:wrapper_class, wrapper_class)
      |> assign(:bubble_class, bubble_class)
      |> assign(:is_current_user?, is_current_user?)

    {:ok, socket}
  end

  def handle_event("edit-message", %{"id" => _message_id}, socket) do
    {:noreply, socket}
  end

  def handle_event("delete-message", %{"id" => message_id}, socket) do
    current_user = socket.assigns.current_user
    group_chat? = socket.assigns.current_chat.group_chat?

    chat_owner? =
      if group_chat? do
        socket.assigns.current_chat.owner_id == current_user.id
      else
        true
      end

    case Integer.parse(message_id) do
      {message_id, _} ->
        result =
          if current_user.is_admin or chat_owner? do
            Chat.delete_message(message_id)
          else
            {:error, "forbiden"}
          end

        case result do
          {:ok, _} ->
            send(socket.assigns.parrent, {:message_deleted, message_id})

            {:noreply,
             socket
             |> put_flash(:ok, "message deleted")}

          {:error, _} ->
            {:noreply,
             socket
             |> put_flash(:eror, "cannot delete message")}
        end

      :error ->
        {:noreply,
         socket
         |> put_flash(:eror, "invalid message id")}
    end
  end

  def handle_event("pin-message", %{"id" => _message_id}, socket) do
    {:noreply, socket}
  end

  def handle_event("copy-message", %{"id" => _message_id}, socket) do
    {:noreply, socket}
  end
end
