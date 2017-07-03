# BatchStage

A stage that batches events together and sends them after either a timeout
has occurred, or enough events for the demand have been gathered, whichever
comes first.

## Installation

The package can be installed by adding `batch_stage` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [{:batch_stage, "~> 0.1.0"}]
end
```
