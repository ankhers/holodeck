defmodule HolodeckWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as pages, components, channels, and so on.

  This can be used in your application as:

      use HolodeckWeb, :page
      use HolodeckWeb, :component

  The definitions below will be executed for every page,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def layout do
    quote do
      use Hologram.Component
    end
  end

  def page do
    quote do
      use Hologram.Page
    end
  end

  def component do
    quote do
      use Hologram.Component
    end
  end

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: HolodeckWeb.Endpoint,
        router: HolodeckWeb.Router,
        statics: HolodeckWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate page/component/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
