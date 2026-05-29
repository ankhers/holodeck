defmodule HolodeckWeb.PageController do
  use HolodeckWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
