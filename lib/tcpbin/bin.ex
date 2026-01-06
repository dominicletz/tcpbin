defmodule TcpBin.Bin do
  use GenServer
  alias TcpBin.Bin
  require Logger
  defstruct [:id, :packets, :socket, :udp_socket, :acceptor, :created, :clients, :echo]

  def start() do
    id = "#{rand(5)}-#{System.os_time(:second)}"
    {:ok, _} = GenServer.start(__MODULE__, [id])
    id
  end

  @impl true
  def init([id]) do
    {:ok, _} = Registry.register(Registry, id, self())
    publish_count()
    {:ok, socket} = :gen_tcp.listen(0, mode: :binary, packet: :raw, active: false)
    {:ok, port} = :inet.port(socket)
    {:ok, udp} = :gen_udp.open(port, mode: :binary, active: true)
    pid = self()
    acc = spawn_link(fn -> accept(socket, pid) end)

    {:ok,
     %Bin{
       id: id,
       packets: [],
       socket: socket,
       udp_socket: udp,
       acceptor: acc,
       created: NaiveDateTime.utc_now(),
       clients: %{},
       echo: false
     }}
  end

  def subscribe(id) do
    :ok = Phoenix.PubSub.subscribe(Tcpbin.PubSub, id)
  end

  def publish(id, data) do
    :ok = Phoenix.PubSub.broadcast(Tcpbin.PubSub, id, data)
  end

  def subscribe_count() do
    :ok = Phoenix.PubSub.subscribe(Tcpbin.PubSub, "bin_count")
  end

  def publish_count() do
    :ok = Phoenix.PubSub.broadcast(Tcpbin.PubSub, "bin_count", count())
  end

  def count() do
    Registry.count(Registry)
  end

  def created(id), do: call(id, :created)
  def packets(id), do: call(id, :packets)
  def port(id), do: call(id, :tcp_port)
  def echo(id), do: call(id, :echo)
  def toggle_echo(id), do: call(id, :toggle_echo)

  @impl true
  def handle_call(:created, _from, %Bin{created: created} = bin) do
    {:reply, created, bin}
  end

  @impl true
  def handle_call(:packets, _from, %Bin{packets: packets} = bin) do
    {:reply, packets, bin}
  end

  @impl true
  def handle_call(:tcp_port, _from, %Bin{socket: socket} = bin) do
    {:ok, port} = :inet.port(socket)
    {:reply, port, bin}
  end

  @impl true
  def handle_call(:echo, _from, %Bin{echo: echo} = bin) do
    {:reply, echo, bin}
  end

  @impl true
  def handle_call(:toggle_echo, _from, %Bin{echo: echo, id: id} = bin) do
    new_echo = !echo
    publish(id, {:echo, new_echo})
    {:reply, new_echo, %Bin{bin | echo: new_echo}}
  end

  @impl true
  def handle_info({:tcp_open, port}, %Bin{clients: clients} = bin) do
    bin = %Bin{bin | clients: Map.put(clients, port, :inet.peername(port))}
    add_packet(bin, port, %{type: :open})
  end

  @impl true
  def handle_info({:tcp_closed, port}, bin) do
    add_packet(bin, port, %{type: :close})
  end

  def handle_info({:udp, _socket, ip, in_port_no, data}, %Bin{clients: clients} = bin) do
    port = {ip, in_port_no}
    bin = %Bin{bin | clients: Map.put(clients, port, {:ok, {ip, in_port_no}})}
    add_packet(bin, port, %{data: data, type: :udp})
  end

  def handle_info({:tcp, port, data}, %Bin{echo: echo} = bin) do
    if echo do
      case :gen_tcp.send(port, data) do
        :ok -> :ok
        {:error, _reason} -> :ok
      end
    end
    add_packet(bin, port, %{data: data, type: :data})
  end

  defp add_packet(%Bin{id: id, packets: packets, clients: clients} = bin, port, packet) do
    packet =
      Map.merge(packet, %{
        created: NaiveDateTime.utc_now(),
        from: Map.get(clients, port)
      })

    publish(id, packet)
    {:noreply, %Bin{bin | packets: [packet | packets]}}
  end

  defp call(id, args) do
    name = {:via, Registry, {Registry, id}}
    GenServer.call(name, args)
  end

  defp accept(listener, pid) do
    case :gen_tcp.accept(listener) do
      {:ok, socket} ->
        :ok = :gen_tcp.controlling_process(socket, pid)
        send(pid, {:tcp_open, socket})
        :ok = :inet.setopts(socket, active: true)

      # GenServer.cast(:accept, socket)
      {:error, err} ->
        Logger.error("Accept error: #{inspect(err)}")
    end

    accept(listener, pid)
  end

  defp rand(n) do
    Enum.map(1..n, fn _n -> rand() end)
    |> List.to_string()
  end

  defp rand() do
    Enum.random(~c"0123456789abcdefghijklmnopqrstuvwxyz")
  end
end
