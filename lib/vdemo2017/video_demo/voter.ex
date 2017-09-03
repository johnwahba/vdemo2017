defmodule Vdemo2017.Voter do
  use GenServer

  def start_link(dir \\ "media/*") do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end
  def init(:ok) do
    {:ok, %{"yay" => 0, "nay" => 0}}
  end

  def get_results do
    GenServer.call(__MODULE__, :get_results)
  end

  def vote(vote) do
    GenServer.cast(__MODULE__, {:vote, vote})
  end

  def handle_call(:get_results, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:vote, vote}, state) do
    state = update_in(state[vote], &(&1 + 1))
    {:noreply, state}
  end
end
