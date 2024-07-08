defmodule TcpbinWeb.Router do
  use TcpbinWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TcpbinWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TcpbinWeb do
    pipe_through :browser

    live "/", PageLive, :index
    live "/bin/:bin/", BinLive, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", TcpbinWeb do
  #   pipe_through :api
  # end
end
