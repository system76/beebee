import Config

# Configures Elixir's Logger
config :logger,
  backends: [LoggerJSON]

config :logger_json, :backend,
  formatter: LoggerJSON.Formatters.DatadogLogger,
  metadata: :all
