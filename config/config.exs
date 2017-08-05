# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :vdemo2017,
  ecto_repos: [Vdemo2017.Repo]

# Configures the endpoint
config :vdemo2017, Vdemo2017Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Uvb3QVHgELGDTm4VZVfpPLk0uU8dJV/uvjcvm/t6fXfVyZdVlfTt6FEhi+LZkiYq",
  render_errors: [view: Vdemo2017Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Vdemo2017.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
