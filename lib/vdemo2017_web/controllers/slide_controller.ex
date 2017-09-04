defmodule Vdemo2017Web.SlideController do
  use Vdemo2017Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
