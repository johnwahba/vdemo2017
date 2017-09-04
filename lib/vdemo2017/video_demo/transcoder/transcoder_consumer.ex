defmodule Vdemo2017.TranscoderConsumer do
  use ConsumerSupervisor

  def start_link() do
    ConsumerSupervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [worker(Vdemo2017.Transcoder, [], restart: :temporary)]
    {:ok, children, strategy: :one_for_one, subscribe_to: [{Vdemo2017.TranscoderProducer, max_demand: 2}]}
  end
end
