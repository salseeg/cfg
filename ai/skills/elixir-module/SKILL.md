---
name: elixir-module
description: Structure Elixir modules within a configurable line limit (default 300, overridable per project in CLAUDE.md) — escalation ladder for splitting, facade patterns, context organization, and naming conventions. Use when a module is too big, when splitting responsibilities, when organizing a new context namespace, or when `make check` reports a file is too long. Triggers when Claude creates or refactors Elixir modules, or when a user asks about module organization.
---

# Elixir Module Structure

Every module should stay under the project's line limit (default: 300 lines, overridable in project CLAUDE.md). `make check` enforces this. When a module grows past that, follow the escalation ladder — try each step in order, stop when you're under the limit.

For function-level structure (30-40 line max, pipe/select/railway shapes), see the **elixir-functions** skill.

## Generic Escalation Ladder

When any module exceeds the line limit, try these steps in order — stop when you're under the limit:

1. **Extract private helper cluster** — find `defp` groups that only call each other, move to a sibling module
2. **Split by operation type** — separate struct/schema from CRUD/business logic into sibling modules
3. **Split by lifecycle phase** — give setup/run/teardown their own sub-modules under the parent
4. **Facade with `defdelegate`** — when a namespace has 3+ modules, add a context entry point
5. **Behaviour + `__using__`** — when 3+ modules share the same callback skeleton, inject defaults via macro

For module-type-specific strategies, see the next section.

## Splitting by Module Type

Each module type has its own internal structure and escalation path. Use the type-specific ladder that matches your module.

### Context (Domain)

A context is the public API for a domain. Internal structure and escalation:

1. **Queries** — extract query functions to a dedicated `MyContext.Queries` module
2. **Subcontexts** — group related operations into sub-modules (`MyContext.Registration`, `MyContext.Billing`)
3. **Facade** — the context module becomes a thin entry point with `defdelegate` and coordination wrappers

```elixir
# Step 1: Accounts context with extracted queries
#   accounts.ex         — public API, orchestration
#   accounts/queries.ex — all Ecto query functions

# Step 2: subcontexts emerge
#   accounts.ex                    — facade
#   accounts/registration.ex       — signup, confirmation
#   accounts/authentication.ex     — login, sessions, tokens

# Step 3: facade delegates
defdelegate register(attrs), to: Accounts.Registration
defdelegate authenticate(email, password), to: Accounts.Authentication
```

### Queries

When a queries module grows, split along two axes:

1. **Read vs Write** — separate query modules for reads and writes
2. **Read further splits** — composable query parts (filters, scopes, joins) and terminal functions (`get`/`all`/`one`)

```elixir
# accounts/queries.ex splits into:
#   accounts/read_queries.ex   — composable: by_email/1, active/1, with_roles/1
#                                 terminal: get/1, all/0, all/1
#   accounts/write_queries.ex  — insert/1, update/2, delete/1

# Composable parts pipe together, terminals execute:
User
|> ReadQueries.active()
|> ReadQueries.by_role(:admin)
|> ReadQueries.all()
```

### Schema

Schemas define data structure. Keep them focused:

- `defstruct` or `schema` + field definitions
- Changesets (validation, casting) — can stay in the schema module
- No business logic, no queries, no side effects

```elixir
defmodule Chat.Accounts.User do
  use Ecto.Schema

  schema "users" do
    field :email, :string
    field :name, :string
    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name])
    |> validate_required([:email, :name])
    |> unique_constraint(:email)
  end
end
```

If changesets grow complex (multiple changeset types, heavy validation), extract to a `Validation` module under the domain — e.g. `Accounts.Validation`.

### GenServer / State Machine

Internal structure: client API at top, then callbacks, then private logic.

Escalation when it grows:

1. **Logic** — extract business logic to a pure module (no process interaction), GenServer calls it
2. **State** — extract state struct and transitions to a dedicated module
3. **Interface** — extract client API to a separate module if many callers need different wrappers

```elixir
# Step 1: logic extraction
#   my_worker.ex        — GenServer: init, handle_call, handle_cast
#   my_worker/logic.ex  — pure functions: calculate/1, decide/2, transform/1

# Step 2: state extraction
#   my_worker/state.ex  — defstruct, new/1, transition/2, valid?/1

# Step 3: interface extraction
#   my_worker/api.ex    — start_link, get, put, sync (GenServer.call wrappers)
#   my_worker.ex        — callbacks only
```

### LiveView

Internal structure follows this order: `mount` → `render` → event handlers → private logic.

Escalation:

1. **Logic** — extract business logic to helper modules, keep LiveView as a thin coordinator
2. **Components** — extract markup into LiveComponents and `.heex` files
3. **Event routing** — extract event handlers to Router modules (see generic Step 3)

```elixir
# Typical small LiveView layout:
def mount(_params, _session, socket), do: ...
def render(assigns), do: ...
def handle_event("save", params, socket), do: ...
def handle_event("delete", params, socket), do: ...
defp load_data(socket), do: ...

# Step 1: logic out
#   my_live.ex         — mount, render, handle_event (thin)
#   my_live/helpers.ex — load_data, process_form, validate_input

# Step 2: components out
#   my_live.html.heex           — main template
#   components/my_form.ex       — LiveComponent for the form
#   components/my_list.ex       — LiveComponent for the list

# Step 3: event routing (for large LiveViews like MainLive.Index)
#   my_live.ex                  — mount, render, handle_event dispatches by prefix
#   my_live/dialog_router.ex   — dialog event handling
#   my_live/room_router.ex     — room event handling
```

### Controller

Controllers stay flat. No escalation tree — if a controller is too big, the domain logic is in the wrong place.

A controller action does two things: **parse params** and **call context functions**. Business logic belongs in contexts, not controllers.

```elixir
def create(conn, %{"user" => user_params}) do
  case Accounts.register(user_params) do
    {:ok, user} -> conn |> redirect(to: ~p"/users/#{user}")
    {:error, changeset} -> conn |> render(:new, changeset: changeset)
  end
end
```

### Router

Phoenix routers can split into sub-routers when scope blocks multiply.

```elixir
# router.ex — top-level scopes and pipelines
scope "/api", MyAppWeb.Api, as: :api do
  pipe_through :api
  forward "/v1", V1Router
  forward "/v2", V2Router
end

# api/v1_router.ex — version-specific routes
defmodule MyAppWeb.Api.V1Router do
  use MyAppWeb, :router
  scope "/" do
    resources "/users", UserController
    resources "/posts", PostController
  end
end
```

## Context Organization

When to create a **new top-level context** vs a **sub-namespace**:

**New context** when the concept has its own persistence, its own struct, and its own lifecycle. It stands alone — removing it wouldn't break unrelated features.

**Sub-namespace** when the module is a decomposition of an existing context's responsibility. It doesn't make sense outside the parent context.

**Rule of thumb**: if the module has no meaning without its parent context, it's a sub-namespace. If it could be a dependency, it's a context.

## Module Principles

1. **One topic per module.** Every module is devoted to a single topic — one struct, one concern, one responsibility. If you can't describe the module's purpose in one sentence without "and", it's doing too much.

2. **Reference order: `use`, `require`, `import`, `alias`.** Always in this order at the top of the module, after `@moduledoc`. Aliases stay alphabetical, grouped by namespace.

   ```elixir
   defmodule Chat.Rooms.RoomMessages do
     @moduledoc "Message CRUD for rooms"

     use Ecto.Schema

     require Logger

     import Ecto.Query

     alias Chat.Db
     alias Chat.Rooms.Message
     alias Chat.Rooms.Room
   ```

3. **Lead with the crucial function or struct.** The module's main public function (or `defstruct`) comes first — this is what a reader is looking for. Supporting public functions follow, then privates.

4. **Private function placement.** A `defp` used by only one function goes right after that function. A `defp` used by multiple functions goes at the bottom of the module.

   ```elixir
   def process(data) do
     data |> validate() |> transform()
   end

   defp validate(data), do: ...   # only used by process/1 — lives right here

   def export(data) do
     data |> format() |> compress()
   end

   defp format(data), do: ...     # only used by export/1 — lives right here

   # --- shared helpers at the bottom ---

   defp compress(data), do: ...   # used by both process/1 and export/1
   ```

5. **One struct per module.** If a module defines `defstruct`, it owns that struct's field-level logic. Operations, messaging, and coordination belong in sibling modules.

6. **Naming reflects the split axis.** After splitting, each name should make the axis obvious:
   - `Room` / `RoomMessages` / `RoomInput` — split by operation type
   - `Lifecycle` / `Lifecycle.Init` / `Lifecycle.Cleanup` — split by phase
   - `DialogRouter` — split by delegation role

7. **Facade is optional.** Only add a context facade (Step 4) when external callers exist. Internal-only namespaces don't need one — direct calls between siblings are fine.

8. **`@moduledoc` explains the split.** After splitting, each module's `@moduledoc` should name what it owns and reference its siblings, so a reader landing anywhere understands the namespace.

## Anti-Patterns

1. **Namespace trespassing.** Module namespace must match file path. Don't define `MyApp.Rooms.Room` in a file under `my_app/dialogs/`.

2. **God module with unrelated functions.** If a module has public functions for users AND rooms AND admin, it should be three modules. This is the primary cause of 300-line violations.

3. **Scattered process interface.** A GenServer's `start_link`, client API (`call`/`cast` wrappers), and callbacks should live in one module — the broker pattern. Don't spread `GenServer.call(SomeServer, ...)` across caller modules.

4. **Premature splitting.** A 200-line module with cohesive functions does not need splitting. The limit is the project's configured maximum, not half of it. Split when you hit the limit or when the module clearly serves two unrelated purposes.

5. **`use` without a behaviour.** If there are no callbacks to override, prefer `import` or a regular function call. `__using__` macros that just inject imports make debugging harder — the reader can't see what's in scope.

6. **Pure-delegate facade.** If a facade is nothing but `defdelegate` lines with zero coordination logic, callers can just alias the implementation module directly. A facade earns its existence by providing a stable API or coordinating between sub-modules.
