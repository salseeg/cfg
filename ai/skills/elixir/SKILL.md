---
name: elixir
description: Write idiomatic Elixir code. Use when writing, reviewing, or debugging Elixir, Phoenix, LiveView, or Ecto code. Enforces assertive pattern matching over defensive programming.
allowed-tools: Read, Edit, Write, Grep, Glob, Bash
---

# Idiomatic Elixir Development

Based on lessons from 150k+ lines of production Elixir code.

## Core Principles

### 1. Assertive Code Over Defensive Programming

**NEVER** write defensive nil-checking or if/else chains. Use pattern matching to assert expectations.

Prefer a single function definition with `case` for branching. Use multi-clause functions only when each clause is truly trivial (for example, one-line formatters or direct pass-through guards).

```elixir
# BAD - Defensive (Python/Ruby style)
def process_user(user) do
  if user != nil do
    if user.email != nil do
      send_email(user.email)
    else
      {:error, :no_email}
    end
  else
    {:error, :no_user}
  end
end

# GOOD - Assertive (Project style: prefer case for branching)
def process_user(user) do
  case user do
    %User{email: email} when is_binary(email) ->
      send_email(email)

    %User{email: nil} ->
      {:error, :no_email}

    nil ->
      {:error, :no_user}
  end
end
```

### 2. Let It Crash Philosophy

Don't catch errors that indicate programmer mistakes. Let processes crash and supervisors restart them.

```elixir
# BAD - Over-defensive
def get_config(key) do
  try do
    Application.fetch_env!(:my_app, key)
  rescue
    _ -> nil
  end
end

# GOOD - Fail fast, fix the config
def get_config(key) do
  Application.fetch_env!(:my_app, key)
end
```

### 3. Pattern Match in Function Heads

Extract data via pattern matching, not intermediate variables.

```elixir
# BAD
def handle_event("save", params, socket) do
  name = params["name"]
  email = params["email"]
  # ...
end

# GOOD
def handle_event("save", %{"name" => name, "email" => email}, socket) do
  # ...
end
```

### 4. Use `with` for Happy Path Pipelines

Chain operations that may fail, pattern matching on success at each step.

```elixir
# GOOD
def create_order(params) do
  with {:ok, user} <- fetch_user(params.user_id),
       {:ok, product} <- fetch_product(params.product_id),
       {:ok, order} <- Orders.create(%{user: user, product: product}) do
    {:ok, order}
  end
end
```

## Phoenix LiveView Patterns

### Handle Events with Multiple Clauses

```elixir
# Pattern match on event names and extract params in function head
def handle_event("delete", %{"id" => id}, socket) do
      # ...
  end

def handle_event("update", %{"id" => id, "value" => value}, socket) do
  # ...
end
```

### Assign Updates

```elixir
# BAD
socket = assign(socket, :loading, true)
socket = assign(socket, :error, nil)

# GOOD
socket
|> assign(:loading, true)
|> assign(:error, nil)

# BETTER for multiple assigns
assign(socket, loading: true, error: nil)
```

## Ecto Patterns

### Changesets with Pattern Matching

```elixir
def changeset(%User{} = user, attrs) do
  user
  |> cast(attrs, [:name, :email])
  |> validate_required([:name, :email])
  |> validate_format(:email, ~r/@/)
  |> unique_constraint(:email)
end
```

### Query Composition

```elixir
# Build queries with pipes
def list_active_users(opts \\ []) do
  User
  |> where(active: true)
  |> maybe_filter_by_role(opts[:role])
  |> order_by([u], desc: u.inserted_at)
  |> Repo.all()
end

defp maybe_filter_by_role(query, nil), do: query
defp maybe_filter_by_role(query, role), do: where(query, role: ^role)
```

## OTP and Concurrency

**IMPORTANT**: When debugging GenServer, Task, or process issues:

1. Check the process is alive: `Process.alive?(pid)`
2. Check message queue: `:sys.get_state(pid)` or `Process.info(pid, :message_queue_len)`
3. Use `:observer.start()` for visual debugging
4. Add telemetry/logging at process boundaries
5. Remember: test database sandboxes use transactions - data won't be visible across processes in tests

### GenServer Template

```elixir
defmodule MyApp.Worker do
  use GenServer

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get_state, do: GenServer.call(__MODULE__, :get_state)

  # Server Callbacks
  @impl true
  def init(opts) do
    {:ok, %{data: opts[:initial_data]}}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:update, data}, state) do
    {:noreply, %{state | data: data}}
  end
end
```

## Testing Patterns

### Use ExUnit Tags and Setup

```elixir
defmodule MyApp.UserTest do
  use MyApp.DataCase, async: true

  describe "create_user/1" do
    test "with valid attrs creates user" do
      assert {:ok, %User{}} = Accounts.create_user(%{name: "Test", email: "test@example.com"})
    end

    test "with invalid email returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(%{name: "Test", email: "invalid"})
    end
  end
end
```

### Async Test Considerations

When tests touch the database AND spawn processes, use `async: false` or explicitly checkout connections:

```elixir
# In async tests that spawn processes
Ecto.Adapters.SQL.Sandbox.allow(Repo, self(), pid)
```

## Architecture Guidelines

When working on Elixir projects:

1. **Contexts over scattered modules** - Group related functions in context modules (e.g., `Accounts`, `Orders`)
2. **Avoid code duplication** - Extract shared logic to private functions or shared modules
3. **Keep modules focused** - One responsibility per module
4. **Use structs for domain entities** - Prefer `%User{}` over plain maps for domain objects

## Common Anti-Patterns to Avoid

| Anti-Pattern | Idiomatic Alternative |
|--------------|----------------------|
| `if x != nil` | Pattern match: `def f(%{x: x}) when not is_nil(x)` |
| Nested if/else | `case` or `with` |
| `try/rescue` for control flow | Pattern match on `{:ok, _}` / `{:error, _}` |
| `Enum.map` + `Enum.filter` | `Enum.filter` then `Enum.map`, or `for` comprehension |
| String concatenation `<>` in loops | `IO.iodata_to_binary` with iolists |
| Manual recursion for lists | `Enum` functions |

## Before Submitting Code

1. Run `mix format`
2. Run `mix credo --strict`
3. Run `mix dialyzer` if configured
4. Ensure tests pass: `mix test`
