defmodule PoolGuy do
  use Application

  @moduledoc """
  Documentation for PoolGuy.
  """
  def start(_type, _args) do
    pool_config = [name: "Pool", mfa: {SampleWorker, :start_link, [[]]}, size: 3]
    start_pool(pool_config)
  end

  def start_pool(pool_config) do
    PoolGuy.Supervisor.start_link(pool_config)
  end

  @doc """
  checkout

  ## Examples

      iex> PoolGuy.checkout
      :world

  """
  def checkout do
    PoolGuy.Server.checkout
  end

  @doc """
  checkin

  ## Examples

      iex> PoolGuy.checkin(worker_pid)
      :world

  """
  def checkin(worker_pid) do
    PoolGuy.Server.checkin(worker_pid)
  end

  @doc """
  status

  ## Examples

      iex> PoolGuy.status(name)
      :world

  """
  def status do
    PoolGuy.Server.status
  end
end
