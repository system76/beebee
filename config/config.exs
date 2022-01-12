import Config

# Configures Redis connection
# For a full list of configuration options, please see:
# https://hexdocs.pm/redix/Redix.html#start_link/1-connection-options
config :beebee,
       :storage_backend,
       {BeeBee.Storage.Redis,
        [
          host: System.get_env("REDIS_HOST", "127.0.0.1"),
          port: System.get_env("REDIS_PORT", "6379") |> String.to_integer(),
          password: System.get_env("REDIS_PASSWORD", ""),
          database: 0
        ]}

# Configures Elixir's Logger
config :logger,
  backends: [LoggerJSON]

config :logger_json, :backend,
  formatter: LoggerJSON.Formatters.DatadogLogger,
  metadata: :all
