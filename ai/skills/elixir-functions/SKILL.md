---
name: elixir-functions
description: Structure Elixir functions for readability — fit on one screen, clear control flow, single-clause with internal branching. Use this skill whenever writing, reviewing, or refactoring Elixir function bodies. Triggers automatically when Claude writes Elixir code, and also when a user asks about function structure, control flow, or readability in Elixir.
---

# Elixir Function Structure

A function is read as one unit, without scrolling. 30-40 lines is a smell, not a limit: one coherent 50-line function beats three that only make sense together.

## Rules

1. **One primary shape per body**: pipe, select, or railway (see below). A pipe may end in a `case`; a select may hold a short pipe. If no single shape fits, the function does too much.
2. **One level of branching.** A `case` inside a `case` branch means `with` or extract.
3. **Declarative or implementive, not alternating.** Either the body calls named helpers, or it does the work. A one-liner between named calls is fine; a multi-line logic block between them is not.
4. **Standalone names.** The name must make sense in a stack trace without seeing the caller: `apply_discount`, not `step_three` or `prepare_for_validation`. If the best name says *where* the code runs, keep it inline. Exception: `do_foo/N` recursion accumulators.
5. **Depth budget of two.** Orchestrator and its workers. If understanding needs a third hop, the splits destroyed locality.
6. **Extract only for reuse or shape.** Used in two places, or complex enough that inlining breaks the parent's shape. A 3-line transform used once stays inline.
7. **Subject first.** The main argument comes first so the call pipes: `["Stopping ", run_dir] |> log(:info)`. Build messages as iolists, not interpolation.
8. **One return shape per function.** Never `nil` on one path and `{:error, _}` on another.
9. **No defensive checks mid-pipe.** No nil guards, no error-tuple handling between steps. Wrong data crashes.
10. **Fail closed at security boundaries.** When a branch decides access, enumerate the values that allow it and reject everything else. A catch-all that passes through is a hole.
11. **`try`/`rescue` is not a shape.** Only at the boundary with a library that raises, alone in its own function.

## Clauses

Multi-clause is for one-liners. Multi-line bodies side by side hide the control flow.

Allowed: all clauses are `, do:` one-liners, or one-liners plus **at most one** multi-line clause, placed first or last. Anything else becomes a single clause with `case`/`cond`/`with` inside.

```elixir
# fine: one-liners
defp pub_key(%Identity{public_key: key}), do: key
defp pub_key(%Card{pub_key: key}), do: key

# fine: one-liners plus a single multi-line clause, last
def handle_info(:tick, state), do: {:noreply, schedule(state)}
def handle_info({:chunk, data}, state) do
  state = append(state, data)
  {:noreply, maybe_flush(state)}
end

# not fine: two multi-line clauses -> one clause, case inside
```

Use `when` guards for type and range checks instead of `if` in the body; `defguard` for repeated ones.

## Shapes

### Pipe

Linear transform. `then/2` reshapes a value, `tap/2` for side effects. End in `case` when the pipe transforms and the tail picks the outcome; `then/2` with a multi-clause fn only when `case` cannot destructure it.

```elixir
device
|> normalize_device_path()
|> Maintenance.device_to_path()
|> case do
  nil -> :nothing_to_unmount
  path -> Mount.unmount(path)
end
```

Hygiene: no pipe starting with a call (`foo(x) |> bar()`), no single-step pipes, no `|> (fn ... end).()`. Name an intermediate when the value is used twice or the pipe passes ~6 steps.

### Select

- `case`: value shape
- `if`: one boolean
- `cond`: several booleans
- `with` (happy path): fallible steps chained, first failure falls through
- `with` (inverse): the *unhappy* conditions in the head, body handles the failure, `else` passes through

`else` receives the mismatch from **every** clause. With more than one fallible step, tag each error (`{:error, :fetch}`) or drop `else` and return the mismatch as is.

```elixir
# inverse with: detect one problem, otherwise pass through
defp fail_invalid_user_card(changeset) do
  with true <- changeset.valid?,
       card <- Ecto.Changeset.apply_changes(changeset),
       false <- UserData.valid_card?(card) do
    Ecto.Changeset.add_error(changeset, :user_hash, "invalid_user_card_integrity")
  else
    _ -> changeset
  end
end
```

The `_ -> changeset` above is fail-open: any unexpected value passes. When the inverse `with` guards access (rule 10), `else` lists the known pass-through values explicitly and the final `_` adds the error:

```elixir
  else
    {:ok, _} -> changeset   # vouch chain found
    true -> changeset       # owner exempt
    "open" -> changeset     # no gate in open mode
    _ -> Ecto.Changeset.add_error(changeset, :author_hash, "not invited")
  end
```

### Railway

A chain of fallible steps whose shapes differ between steps, when `with` would not stay flat. Declare steps as anonymous functions at the top (they close over locals, so nothing is threaded through parameters), name them *action + data*, pipe through `go_on` at the bottom. A step returns `:ok` / `{:ok, _}` / `{:error, _}` to stop; any other value flows to the next step.

```elixir
def stop(opts) do
  data_dir = Path.join(Keyword.fetch!(opts, :pg_dir), "data")

  stop_server = fn
    false -> :ok
    true -> run_pg("pg_ctl", ["-D", data_dir, "stop", "-m", "fast"])
  end

  report_stop = fn
    {_, 0} -> :ok
    {output, _} -> {:error, output}
  end

  server_running?(opts)
  |> go_on(stop_server)
  |> go_on(report_stop)
end

def go_on(data, step) do
  case data do
    {:error, _} -> data
    {:ok, _} -> data
    :ok -> data
    _ -> step.(data)
  end
end
```

If the codebase has no `go_on`, add it to a shared utility module. Use `Ecto.Multi` for DB transactions and `Enum.reduce_while` for a homogeneous accumulator instead.

## Review checklist

- One primary shape, recognizable at a glance
- One level of branching
- Names stand alone without the caller
- Two hops max from the public function to the work
- Clauses: one-liners, plus at most one multi-line clause, first or last
- One return shape
- Subject-first arguments, iolists for messages
- Nothing extracted that is used once and reads fine inline
