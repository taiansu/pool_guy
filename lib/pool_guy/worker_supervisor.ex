defmodule PoolGuy.WorkerSupervisor do
  use DynamicSupervisor

  ### API
  def start_link(pool_config) do
    DynamicSupervisor.start_link(__MODULE__, pool_config,
      name: via_tuple(pool_config[:name])
    )
  end

  def start_worker(name, mfa) do
    child_spec = %{id: :"{name}Worker", start: mfa, restart: :temporary}

    DynamicSupervisor.start_child(via_tuple(name), child_spec)
  end

  def via_tuple(pool_name) do
    {:via, Registry, {PoolGuy.Registry, "#{pool_name}WorkerSupervisor"}}
  end

  @impl true
  def init(_pool_config) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
