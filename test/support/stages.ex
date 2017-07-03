defmodule BatchStageTest.Producer do
  use GenStage

  def start_link() do
    GenStage.start_link(__MODULE__)
  end

  def init(counter) do
    {:producer, counter}
  end

  def handle_demand(demand, counter) when demand > 0 do
    events = Enum.to_list(counter..counter+demand-1)
    {:noreply, events, counter + demand}
  end
end

defmodule BatchStageTest.Sink do
  use GenStage

  def start_link() do
    GenStage.start_link(__MODULE__, {0, 0})
  end

  def init({events, batches}) do
    {:consumer, {events, batches}}
  end

  def handle_events(e, _from, {events, batches}) do
    {:noreply, [], {events + length(e), batches + 1}}
  end

  def get(pid) do
    GenStage.call(pid, :get)
  end

  def handle_call(:get, _from, state), do: {:reply, state, [], state}
end
