defmodule TcpBin.Bin do
  use GenServer
  alias TcpBin.Bin
  require Logger
  defstruct [:id, :packets, :socket, :acceptor, :created]

  def start() do
    id = "#{rand(5)}-#{System.os_time(:second)}"
    {:ok, _} = GenServer.start(__MODULE__, [id])
    id
  end

  @impl true
  def init([id]) do
    {:ok, _} = Registry.register(Registry, id, self())
    {:ok, socket} = :gen_tcp.listen(0, mode: :binary, packet: :raw, active: false)
    pid = self()
    acc = spawn_link(fn -> accept(socket, pid) end)

    {:ok,
     %Bin{id: id, packets: [], socket: socket, acceptor: acc, created: NaiveDateTime.utc_now()}}
  end

  def subscribe(id) do
    :ok = Phoenix.PubSub.subscribe(Tcpbin.PubSub, id)
  end

  def publish(id, data) do
    :ok = Phoenix.PubSub.broadcast(Tcpbin.PubSub, id, data)
  end

  def created(id), do: call(id, :created)
  def packets(id), do: call(id, :packets)
  def port(id), do: call(id, :tcp_port)

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
  def handle_info({:tcp_open, port}, %Bin{id: id, packets: packets} = bin) do
    add_packet(bin, %{
      created: NaiveDateTime.utc_now(),
      from: :inet.peername(port),
      type: :open
    })
  end

  @impl true
  def handle_info({:tcp_closed, port}, %Bin{id: id, packets: packets} = bin) do
    add_packet(bin, %{
      created: NaiveDateTime.utc_now(),
      from: :inet.peername(port),
      type: :close
    })
  end

  def handle_info({:tcp, port, data}, bin) do
    add_packet(bin, %{
      created: NaiveDateTime.utc_now(),
      from: :inet.peername(port),
      data: data,
      type: :data
    })
  end

  defp add_packet(%Bin{id: id, packets: packets} = bin, packet) do
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
    Enum.random('0123456789abcdefghijklmnopqrstuvwxyz')
  end
end
