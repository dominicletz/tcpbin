defmodule Tcpbin do
  @moduledoc """
  Tcpbin keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def host() do
    Application.get_env(:tcpbin, TcpbinWeb.Endpoint) |> get_in([:url, :host]) || "localhost"
  end
end
