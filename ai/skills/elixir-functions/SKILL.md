---
name: elixir-functions
description: Structure Elixir functions for readability — fit on one screen, clear control flow, single-clause with internal branching. Use this skill whenever writing, reviewing, or refactoring Elixir function bodies. Triggers automatically when Claude writes Elixir code, and also when a user asks about function structure, control flow, or readability in Elixir.
---

# Elixir Function Structure

Every function should be readable as a self-contained unit — understandable without scrolling. Aim for 30-40 lines max. When a function grows beyond that, it's doing too much.

## Declarative vs Implementive

A function is either **declarative** — showing *what* happens by calling well-named helpers — or **implementive** — showing *how* something works with actual logic.

Mixing is fine when the implementation bits are dead simple (a one-liner between named calls), but if you're alternating between named calls and multi-line logic blocks, extract.

```elixir
# Declarative — reads like a plan
def user_card_validate(card, changes, :insert) do
  card
  |> UserCard.create_changeset(changes)
  |> validate_signature()
  |> fail_invalid_user_card()
end

# Implementive — shows the actual work
def calculate_totals(%{items: items} = order) do
  total =
    items
    |> Enum.map(& &1.price * &1.quantity)
    |> Enum.sum()

  %{order | total: total}
end
```

## Naming

A function name should describe what *this function does* as a standalone piece — not its role inside a larger flow. Someone reading the name in a stack trace, a grep result, or a module index should understand its purpose without needing to see the caller.

```elixir
# Weak — only makes sense inside a specific pipeline
defp step_three(data)

# Strong — self-contained meaning
defp apply_discount(order)
defp fail_invalid_user_card(changeset)
defp capture_pg_crash_logs(pg_dir)
```

## Single-Clause Functions

Prefer one function clause with internal branching (`case`/`cond`/`with`) over multiple clauses. All paths sit on one screen and the reader sees the full picture.

Multi-clause is fine for truly trivial cases — one-line formatters, protocol implementations, or when the function head pattern match *is* the entire logic:

```elixir
# Fine as multi-clause — each clause is one line
defp pub_key(%Identity{public_key: key}), do: key
defp pub_key(%Card{pub_key: key}), do: key
defp pub_key(%Room{pub_key: key}), do: key
```

## Control Flow

There are three shapes a function body should take. If you're reaching for something else, reconsider the structure.

### 1. Pipe — linear transformation

Data flows in one direction through a sequence of steps. No branching, no error handling — just transform. Use `then/2` for inline value reshaping and `tap/2` for side effects that shouldn't alter the data.

```elixir
def format_report(raw_data) do
  raw_data
  |> parse_entries()
  |> group_by_category()
  |> sort_by_date()
  |> render_table()
end

def store_and_notify(parcel) do
  parcel
  |> tap(fn p -> Enum.each(p.data, fn {key, val} -> Db.put(key, val) end) end)
  |> tap(&notify_subscribers/1)
  |> then(fn p -> {:ok, p.id} end)
end
```

### 2. Select — choosing between two outcomes

When a function produces one of two kinds of result (success/failure, this/that), pick the construct that fits:

- **`case`** — matching on a value's shape
- **`if`** — simple boolean
- **`cond`** — multiple boolean conditions
- **`with`** (happy path) — chaining operations that might fail, first failure falls through
- **`with`** (inverse — unhappy path) — the failure cases go in the `with` body, success goes in `else`

#### `case` for dispatch

```elixir
def heal(device) do
  case Lsblk.fs_type(device) do
    "vfat" -> Fsck.vfat(device)
    "f2fs" -> Fsck.f2fs(device)
    "exfat" -> Fsck.exfat(device)
    _ -> false
  end
end
```

#### `cond` for multiple conditions

```elixir
defp decide(path) do
  cond do
    File.exists?("#{path}/cargo_db")   -> CargoSyncSupervisor
    File.exists?("#{path}/main_db")    -> MainDbSupervisor
    create_first_main?()               -> MainDbSupervisor
    true                               -> default_scenario()
  end
end
```

#### Inverse `with` — handling the unhappy path

Sometimes the interesting work is detecting a problem. The `with` head matches the *unhappy* conditions so the body handles the failure, and `else` handles the normal case:

```elixir
defp fail_invalid_user_card(changeset) do
  with true <- changeset.valid?,
       card_data <- Ecto.Changeset.apply_changes(changeset),
       false <- UserData.valid_card?(card_data) do
    # unhappy: card is invalid — add the error
    Ecto.Changeset.add_error(changeset, :user_hash, "invalid_user_card_integrity")
  else
    # happy: either changeset was already invalid or card passed validation
    _ -> changeset
  end
end
```

Use this when the function's job is "check for a specific problem, otherwise pass through." The `with` body is the exceptional branch; `else` is the common case.

### 3. Early Return — a chain of steps that can bail out

When you have a sequence of operations where any step might end the whole thing, use a list of functions with `Enum.reduce_while`. Each step returns `{:cont, acc}` to continue or `{:halt, result}` to stop.

This replaces deeply nested `with` chains or custom railway helpers. The control flow is standard Elixir — the reader sees the step list up front and knows exactly what can happen.

```elixir
def initialize(opts) do
  [
    &check_already_initialized/1,
    &run_initdb/1,
    &validate_init_result/1,
    &setup_replication/1
  ]
  |> Enum.reduce_while(opts, fn step, acc -> step.(acc) end)
end

defp check_already_initialized(opts) do
  case {initialized?(opts), valid_init?(opts)} do
    {true, true}  -> {:halt, :ok}
    {true, false} -> {:halt, {:error, :incorrectly_initialized}}
    {false, _}    -> {:cont, opts}
  end
end

defp run_initdb(opts) do
  case run_pg("initdb", build_args(opts), as_postgres_user: true) do
    {_, 0} = result -> {:cont, {opts, result}}
    {output, _}     -> {:halt, {:error, output}}
  end
end
```

Each step is a small, named, testable function. The main function is declarative — it lists the steps. The step functions are implementive — they do the work.

## When to split

If a function body doesn't fit one of these three shapes cleanly, it's doing too much. Split it so each piece is one of:
- a pipe
- a select
- an early-return chain

The goal is not rules for their own sake — it's to make the reader's job easy. Every function should have one obvious shape that a reader recognizes immediately.
