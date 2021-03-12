defmodule TcpbinWeb.PageLive do
  alias TcpBin.Bin
  use TcpbinWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    Bin.subscribe_count()
    {:ok, assign(socket, count: Bin.count())}
  end

  @impl true
  def handle_info(count, socket) when is_integer(count) do
    {:noreply, assign(socket, count: count)}
  end

  @impl true
  def handle_event("create", %{}, socket) do
    id = Bin.start()
    {:noreply, push_redirect(socket, to: "/bin/#{id}/")}
  end
end
