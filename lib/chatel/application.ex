defmodule Chatel.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    topologies = [
      example: [
        strategy: Cluster.Strategy.Epmd,
        config: [
          hosts: [
            :node1@AMDRYZENSARCH,
            :node2@AMDRYZENSARCH
          ]
        ]
      ]
    ]

    children = [
      {Cluster.Supervisor, [topologies, [name: Chatel.ClusterSupervisor]]},
      ChatelWeb.Telemetry,
      Chatel.Repo,
      {DNSCluster, query: Application.get_env(:chatel, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Chatel.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Chatel.Finch},
      # Start a worker by calling: Chatel.Worker.start_link(arg)
      # {Chatel.Worker, arg},
      # Start to serve requests, typically the last entry
      ChatelWeb.Endpoint,
      ChatelWeb.Presence,
      Chatel.Vault
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Chatel.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ChatelWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
