defmodule ChatelWeb.CreateChatButton do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <div
      aria-label="Create new chat"
      class="p-1 rounded-full text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 focus:outline-none"
    >
      <.link navigate="/new">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="h-6 w-6"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          stroke-width="2"
        >
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
        </svg>
      </.link>
    </div>
    """
  end
end
