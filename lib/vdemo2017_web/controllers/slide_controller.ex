defmodule Vdemo2017Web.SlideController do
  use Vdemo2017Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def start_stream(conn, _params) do
    Vdemo2017.VideoStreamer.start()
    render conn, "index.html"
  end

  def vote(conn, %{"vote" => vote}) do
    Vdemo2017.Voter.vote(vote)
    render conn, "index.html"
  end
end
