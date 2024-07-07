defmodule App do
  def host() do
    Application.get_env(:tcpbin, TcpbinWeb.Endpoint) |> get_in([:url, :host]) || "localhost"
  end
end
