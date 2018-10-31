defmodule PoolGuy.Supervisor do
  use Supervisor

  def start_link(pool_config) do
    Supervisor.start_link(__MODULE__, pool_config, name: :"#{pool_config[:name]}Supervisor")
  end

  @impl true
  def init(pool_config) do
    children = [
      {Registry, keys: :unique, name: PoolGuy.Registry},
      {PoolGuy.WorkerSupervisor, pool_config},
      {PoolGuy.Server, pool_config}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
