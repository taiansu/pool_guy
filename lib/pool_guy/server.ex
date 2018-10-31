defmodule PoolGuy.Server do
  use GenServer

  alias PoolGuy.WorkerSupervisor

  #######
  # API #
  #######
  def start_link(pool_config) do
    GenServer.start_link(__MODULE__, pool_config, name: via_tuple(pool_config[:name]))
  end

  def checkout do
    GenServer.call(via_tuple("Pool"), :checkout)
  end

  def checkin(pid) do
    GenServer.cast(via_tuple("Pool"), {:checkin, pid})
  end

  def status do
    GenServer.call(via_tuple("Pool"), :status)
  end

  defmodule State do
    defstruct [:name, :mfa, :size, :workers, :monitors]

    # def from_map(%{name: name, mfa: mfa, size: size, monitors: monitors, workers: workers}) do
    #   %State{name: name, mfa: mfa, size: size, monitors: monitors, workers: workers}
    # end
    def from_map(keyword) do
      Enum.reduce(
        keyword,
        %State{},
        fn {k, v}, acc -> Map.put(acc, k, v) end
      )
    end
  end

  # Use Elixir.Registry to manage the process lookup
  def via_tuple(pool_name) do
    {:via, Registry, {PoolGuy.Registry, "#{pool_name}Server"}}
  end

  #############
  # Callbacks #
  #############
  @impl true
  def init(pool_config) do
    Process.flag(:trap_exit, true)

    monitors = :ets.new(:monitors, [:private])
    workers = start_workers(pool_config)

    state =
      pool_config
      |> Keyword.take([:name, :size, :mfa])
      |> Keyword.put(:monitors, monitors)
      |> Keyword.put(:workers, workers)
      |> State.from_map()

    {:ok, state}
  end

  @impl true
  def handle_call(:checkout, {from_pid, _ref}, %{workers: workers, monitors: monitors} = state) do
    case workers do
      [worker | rest] ->
        ref = Process.monitor(from_pid)
        :ets.insert(monitors, {worker, ref})
        {:reply, worker, %{state | workers: rest}}

      [] ->
        {:reply, :noproc, state}
    end
  end

  @impl true
  def handle_cast({:checkin, worker}, %{workers: workers, monitors: monitors} = state) do
    case :ets.lookup(monitors, worker) do
      [{pid, ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(monitors, pid)
        {:noreply, %{state | workers: [pid | workers]}}

      [] ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_info({:EXIT, pid, _reason}, %{workers: workers, name: name, mfa: mfa} = state) do
    rest = workers -- [pid]
    new_worker = start_worker(name, mfa)
    {:noreply, %{state | workers: [new_worker | rest]}}
  end

  # deal with monitor refs
  @impl true
  def handle_info(
        {:DOWN, ref, _, _pid, _},
        %{workers: workers, monitors: monitors} = state
      ) do

    case :ets.match(monitors, {:"$1", ref}) do
      [[pid]] ->
        true = :ets.delete(monitors, pid)

        {:noreply, %{state | workers: [pid | workers]}}
      [] ->
        {:noreply, state}
    end
  end

  defp start_workers(pool_config) do
    %{size: size, name: name, mfa: mfa} = Enum.into(pool_config, %{})

    for _ <- 1..size, do: start_worker(name, mfa)
  end

  defp start_worker(name, mfa) do
    {:ok, worker} = WorkerSupervisor.start_worker(name, mfa)
    Process.link(worker)
    worker
  end
end
