defmodule TcpbinWeb.BinLive do
  alias TcpBin.Bin
  use TcpbinWeb, :live_view

  @impl true
  def mount(%{"bin" => id}, _session, socket) do
    case Registry.lookup(Registry, id) do
      [{pid, _value}] ->
        Bin.subscribe(id)

        {:ok,
         assign(socket,
           pid: pid,
           id: id,
           created: Bin.created(id),
           port: Bin.port(id),
           packets: Bin.packets(id),
           echo: Bin.echo(id),
           page_title: "Bin #{id}"
         )}

      [] ->
        socket =
          put_flash(socket, :info, "Bin '#{id}' doesn't exist anymore... Please create a new bin")

        {:ok, push_navigate(socket, to: "/")}
    end
  end

  @impl true
  def handle_info({:echo, echo}, socket) do
    {:noreply, assign(socket, echo: echo)}
  end

  @impl true
  def handle_info(packet, socket) do
    packets = socket.assigns.packets
    {:noreply, collect(assign(socket, packets: [packet | packets]))}
  end

  @impl true
  def handle_event("toggle_echo", _params, socket) do
    id = socket.assigns.id
    echo = Bin.toggle_echo(id)
    {:noreply, assign(socket, echo: echo)}
  end

  def collect(socket) do
    receive do
      packet ->
        packets = socket.assigns.packets
        collect(assign(socket, packets: [packet | packets]))
    after
      0 ->
        socket
    end
  end

  defp render_from({:ok, {ip, port}}) do
    "#{List.to_string(:inet.ntoa(ip))}:#{port}"
  end

  defp render_from(other) do
    inspect(other)
  end

  @chars ~c'0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ~!@#$%^&*()-_=+{}[]\\|"\':;/?.>,<\n\t '
  defp render_data(data) do
    :binary.bin_to_list(data)
    |> Enum.map(fn c -> if c in @chars, do: c, else: ?. end)
    |> List.to_string()
  end

  defp render_hex(data) do
    :binary.bin_to_list(data)
    |> Enum.chunk_every(2)
    |> Enum.map(fn bin -> Base.encode16(:binary.list_to_bin(bin)) end)
    |> Enum.join(" ")
  end
end
