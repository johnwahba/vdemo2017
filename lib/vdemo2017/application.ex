defmodule Vdemo2017.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Vdemo2017.Repo, []),
      # Start the endpoint when the application starts
      supervisor(Vdemo2017Web.Endpoint, []),
      supervisor(Vdemo2017.Voter, []),
      supervisor(Vdemo2017.VideoStreamer, []),
      worker(Vdemo2017.TranscoderProducer, []),
      supervisor(Vdemo2017.TranscoderConsumer, []),
      # Start your own worker by calling: Vdemo2017.Worker.start_link(arg1, arg2, arg3)
      # worker(Vdemo2017.Worker, [arg1, arg2, arg3]),
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Vdemo2017.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Vdemo2017Web.Endpoint.config_change(changed, removed)
    :ok
  end
end
