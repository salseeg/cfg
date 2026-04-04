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

There are three shapes a function body should take. They can combine naturally (a pipe ending in a case, a select inside `then/2`), but each function should have one *primary* shape that the reader recognizes at a glance.

### 1. Pipe — linear transformation

Data flows in one direction through a sequence of steps. Use `then/2` for inline value reshaping and `tap/2` for side effects that shouldn't alter the data. Do not add defensive nil-checks or error-tuple guards mid-pipe — let it crash if the data is wrong.

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

#### Pipe into select

A pipe can end with a `case` or `then/2` that branches — the pipe does the transformation, the tail picks the outcome. Prefer `case` when it fits; reach for `then/2` only when you need to bind the piped value to a name or destructure it in a way `case` can't express cleanly:

```elixir
def unmount(device) do
  device
  |> normalize_device_path()
  |> Maintenance.device_to_path()
  |> then(fn
    nil  -> :nothing_to_unmount
    path -> Mount.unmount(path)
  end)
end

def file_stats(keys, prefix \\ nil) do
  keys
  |> Dir2.file_path(build_path(prefix))
  |> File.stat(time: :posix)
  |> case do
    {:ok, _} = good -> good
    _ -> keys |> Dir3.file_path(build_path(prefix)) |> File.stat(time: :posix)
  end
end
```

### 2. Select — choosing between a small number of outcomes

When a function picks between a few distinct paths, use the construct that fits the branching condition:

- **`case`** — matching on a value's shape
- **`if`** — simple boolean
- **`cond`** — multiple boolean conditions
- **`with`** (happy path) — chaining operations that might fail, first failure falls through
- **`with`** (inverse — unhappy path) — failure cases go in the `with` body, success goes in `else`

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

Sometimes the interesting work is detecting a problem. The `with` head matches the *unhappy* conditions so the body handles the failure, and `else` handles the normal case.

Note: `<-` in `with` serves double duty — it can guard (match fails → skip to else) or just bind a value for later clauses. In this pattern the first and third clauses are guards (`true <-`, `false <-`), while the middle one is a binding step:

```elixir
defp fail_invalid_user_card(changeset) do
  with true <- changeset.valid?,
       card_data <- Ecto.Changeset.apply_changes(changeset),
       false <- UserData.valid_card?(card_data) do
    # unhappy: card looked valid but integrity check failed
    Ecto.Changeset.add_error(changeset, :user_hash, "invalid_user_card_integrity")
  else
    # normal: changeset already invalid, or card passed validation
    _ -> changeset
  end
end
```

Use this when the function's job is "check for a specific problem, otherwise pass through."

### 3. Railway — a chain of steps that can bail out

When you have a sequence of fallible operations and simpler constructs (`case`, `if`, `with`) don't keep the code flat, declare each step as a named anonymous function, then chain them through a short-circuit helper. Each step either returns a terminal value (`:ok`, `{:ok, _}`, `{:error, _}`) to stop, or a raw value that flows into the next step.

Declare steps as named anonymous functions at the top of the function body, then put the pipeline at the bottom. The variable names document intent, reading order matches execution order, and the pipeline reads as a summary.

```elixir
def stop(opts) do
  pg_data_dir = Path.join(Keyword.fetch!(opts, :pg_dir), "data")
  run_dir = extract_pg_run_dir(pg_dir, opts)

  check_running = fn
    false ->
      ["PostgreSQL server not running"] |> log(:info)
      :ok

    true ->
      ["Stopping PostgreSQL server with run_dir ", run_dir] |> log(:info)
      run_pg("pg_ctl", ["-D", pg_data_dir, "stop", "-m", "fast"],
        as_postgres_user: true, run_dir: run_dir)
  end

  handle_result = fn
    {_, 0} ->
      ["PostgreSQL server stopped successfully"] |> log(:info)
      :ok

    {output, _} ->
      ["PostgreSQL server failed to stop: ", output] |> log(:error)
      {:error, output}
  end

  server_running?(opts)
  |> go_on(check_running)
  |> go_on(handle_result)
end
```

The short-circuit helper is minimal — it passes raw values through and propagates terminal states unchanged:

```elixir
def go_on(data, step_fn) do
  case data do
    {:error, _} -> data
    {:ok, _}    -> data
    :ok         -> data
    _           -> step_fn.(data)
  end
end
```

Steps can produce different shapes between them — unlike `reduce_while`, there's no homogeneous accumulator constraint. Each step pattern-matches on whatever the previous step produced.

## When to split

If a function body doesn't fit one of these three shapes cleanly, it's doing too much. Split it so each piece has one obvious shape.

The goal is not rules for their own sake — it's to make the reader's job easy. A reader should look at any function and immediately recognize: "this is a pipe", "this is a case dispatch", "this is a step chain."
