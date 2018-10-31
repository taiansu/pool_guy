defmodule Consumer do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def stop(pid) do
    GenServer.call(pid, :stop)
  end

  def get_worker(pid) do
    GenServer.call(pid, :get_worker)
  end

  def init(_args) do
    worker = PoolGuy.checkout
    IO.inspect "I got worker: #{inspect(worker)}"
    {:ok, %{worker: worker}}
  end

  def handle_call(:get_worker, _from, %{worker: worker} = state) do
    {:reply, worker, state}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end
end
