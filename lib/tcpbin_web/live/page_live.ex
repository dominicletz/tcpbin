defmodule TcpbinWeb.PageLive do
  alias TcpBin.Bin
  use TcpbinWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("create", %{}, socket) do
    id = Bin.start()
    {:noreply, push_redirect(socket, to: "/bin/#{id}/")}
  end
end
