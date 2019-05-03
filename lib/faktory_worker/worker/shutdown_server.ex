defmodule FaktoryWorker.Worker.ShutdownManager do
  @moduledoc false

  use GenServer
  require Logger

  alias FaktoryWorker.Worker.Server

  @spec start_link(opts :: keyword()) :: Supervisor.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: name_from_opts(opts))
  end

  @spec child_spec(opts :: keyword()) :: Supervisor.child_spec()
  def child_spec(opts) do
    %{
      id: name_from_opts(opts),
      start: {__MODULE__, :start_link, [opts]},
      type: :worker
    }
  end

  @impl true
  def init(opts) do
    Logger.info("[faktory-worker] init shutdown manager")
    Process.flag(:trap_exit, true)
    {:ok, opts}
  end

  @impl true
  def terminate(_reason, state) do
    Logger.info("[faktory-worker] terminate #{inspect(state)}")

    poolname =
      state
      |> FaktoryWorker.Worker.Pool.format_worker_pool_name()

    Logger.info("[faktory-worker] terminate poolname #{inspect(poolname)}")

    children =
      poolname
      |> Supervisor.which_children()

    Logger.info("[faktory-worker] terminate children #{inspect(children)}")

    children
    |> Enum.each(&shutdown_worker/1)
  end

  defp shutdown_worker({_, worker_pid, _, _}) do
    Logger.info("[faktory-worker] shutdown_worker #{inspect(worker_pid)}")

    Server.disable_fetch(worker_pid)
  end

  defp name_from_opts(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    :"#{name}_shutdown_manager"
  end
end