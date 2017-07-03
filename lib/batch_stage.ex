defmodule BatchStage do
  use GenStage
  require Logger

  defstruct [timeout: nil, batch: [], demand: 0, timer: nil, reset_demand: false]

  @moduledoc """
  A stage that will try to batch incoming events into bigger portions so events
  are not sent one-by-one.
  """

  @doc """
  Starts the stage. `args` is a keyword list with these options:

   * `:timeout` - If an event comes in and the internal batch is empty, this
     stage will wait this number of milliseconds before sending it.
     `1_000` by default.
   * `:stage_type` - The stage type `init/1` will return. Can be `:producer` or
     `:consumer_producer`.
     `:producer` by default, or `:consumer_producer` if `:subscribe_to` is not
     empty.
   * `:subscribe_to` - List of subscriptions `init/1` will return. `[]` by
     default.
   * `:demand` - The maximum amount of events to send in one batch.

  The `options` will be passed to the `options` argument of
  `GenStage.start_link/3`.
  """
  def start_link(args, options) do
    GenStage.start_link(__MODULE__, args, options)
  end

  @doc false
  def init(args) do
    subscribe_to = Keyword.get(args, :subscribe_to, [])
    timeout = Keyword.get(args, :timeout, 1_000)
    demand = Keyword.get(args, :demand, 500)

    default_stage_type =
      if length(subscribe_to) == 0,
        do: :producer,
        else: :consumer_producer

    stage_type = Keyword.get(args, :stage_type, default_stage_type)

    state = %__MODULE__{
      timeout: timeout,
      demand: demand,
      reset_demand: stage_type == :producer
    }

    opts = case subscribe_to do
      [] -> []
      subscribe_to -> [subscribe_to: subscribe_to]
    end

    {stage_type, state, opts}
  end

  @doc """
  Appends a number of events to the internal batch asynchronously.
  """
  def append(stage, events) when is_list(events) do
    GenStage.cast(stage, {:append, events})
  end

  @doc """
  Appends a single event to the internal batch.

  If possible, you should use `append/2` instead of `append_one/2`.
  """
  def append_one(stage, event) do
    append(stage, [event])
  end

  @doc false
  def handle_cast({:append, events}, state) do
    {outgoing, state} = handle_incoming(events, state)
    {:noreply, outgoing, state}
  end

  @doc false
  def handle_events(events, _from, state) do
    {outgoing, state} = handle_incoming(events, state)
    {:noreply, outgoing, state}
  end

  @doc false
  def handle_info(:timer_timeout, state) do
    events = state.batch

    state =
      state
      |> Map.put(:timer, nil)
      |> Map.put(:batch, [])

    state = if state.reset_demand do
      Map.update!(state, :demand, &(&1 - length(events)))
    else
      state
    end

    {:noreply, events, state}
  end

  defp handle_incoming(events, state) do
    state = Map.update!(state, :batch, &(&1 ++ events))
    {outgoing, state} = get_outgoing(state)
    state = start_timer(state)
    {outgoing, state}
  end

  defp get_outgoing(state) do
    if state.demand <= length(state.batch) do
      {outgoing, keep} = Enum.split(state.batch, state.demand)

      state =
        state
        |> Map.put(:batch, keep)
        |> stop_timer()
        |> start_timer()

      state = if state.reset_demand do
        Map.put(state, :demand, 0)
      else
        state
      end

      {outgoing, state}
    else
      {[], state}
    end
  end

  defp stop_timer(%{timer: timer} = state) when not is_nil(timer) do
    {:ok, :cancel} = :timer.cancel(state.timer)
    Map.put(state, :timer, nil)
  end
  defp stop_timer(state), do: state

  defp start_timer(%{timer: nil, batch: batch} = state) when length(batch) > 0 do
    {:ok, timer} = :timer.send_after(state.timeout, self(), :timer_timeout)
    Map.put(state, :timer, timer)
  end
  defp start_timer(state), do: state

  @doc false
  def handle_demand(demand, state) do
    state = Map.put(state, :demand, demand)
    {outgoing, state} = get_outgoing(state)
    {:noreply, outgoing, state}
  end
end
