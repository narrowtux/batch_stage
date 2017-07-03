defmodule BatchStageTest do
  use ExUnit.Case
  doctest BatchStage
  alias BatchStageTest.{Producer, Sink}

  test "batch_stage forwards as :producer_consumer" do
    {:ok, producer} = Producer.start_link()
    {:ok, batch_stage} = BatchStage.start_link([stage_type: :producer_consumer], [])
    {:ok, sink} = Sink.start_link()

    GenStage.sync_subscribe(batch_stage, to: producer, min_demand: 13, max_demand: 23)
    GenStage.sync_subscribe(sink, to: batch_stage, min_demand: 500, max_demand: 1000)

    Process.sleep(50)

    assert Sink.get(sink) |> elem(0) > 0

    GenStage.stop(sink)
  end

  test "batch_stage can act as a :producer" do
    {:ok, batch_stage} = BatchStage.start_link([timeout: 20], [])
    {:ok, sink} = Sink.start_link()

    GenStage.sync_subscribe(sink, to: batch_stage, max_demand: 10)

    BatchStage.append_one(batch_stage, 1)

    Process.sleep(40)

    assert Sink.get(sink) |> elem(1) == 1

    BatchStage.append(batch_stage, Enum.into(1..9, []))

    Process.sleep(10)

    {events, batches} = Sink.get(sink)

    assert events == 10 && batches >= 2

    BatchStage.append(batch_stage, Enum.into(1..100, []))

    Process.sleep(200)

    {events, _batches} = Sink.get(sink)

    assert events > 100

    GenStage.stop(sink)
  end
end
