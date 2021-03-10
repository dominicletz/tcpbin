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
           packets: Bin.packets(id)
         )}

      [] ->
        {:error, :not_found}
        # render(ErrorView, "404.html")
        # raise Ecto.NoResultsError
        # {:error, :not_found}
    end
  end

  @impl true
  def handle_event("create", %{}, socket) do
    id = Bin.start()
    {:noreply, push_redirect(socket, to: "/bin/#{id}/")}
  end

  @impl true
  def handle_info(packet, socket) do
    packets = socket.assigns.packets
    {:noreply, assign(socket, packets: packets ++ [packet])}
  end

  defp render_from({:ok, {ip, port}}) do
    "#{List.to_string(:inet.ntoa(ip))}:#{port}"
  end

  defp render_from(other) do
    inspect(other)
  end

  @chars '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ~!@#$%^&*()-_=+{}[]\\|"\':;/?.>,<\n\t '
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
