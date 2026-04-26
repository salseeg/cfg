---
name: jump-test-writing
description: Rules for writing readable, maintainable tests in the Jump Elixir/Phoenix app. Use whenever writing or refactoring tests in /api. Covers test-case size, helper placement, and when to promote helpers to shared test infrastructure.
---

# Readability rules

1. A test case is up to 30–40 lines. If it grows past that, extract setup into helpers.
2. Simple beats clever. Prefer language features over abstractions.
3. Extract repeated code into helper functions.
4. Helper names are descriptive — they read like sentences at the call site.
5. Helper placement:
   - Used by one test → private function right after that test.
   - Used across a `describe` block → at the end of the `describe`.
   - Used across the whole file → at the end of the file.
   - Used across multiple files → promote per the escalation ladder below.
6. Keep **all** `assert`/`refute` calls in the test body. Helpers do setup, getting, or comparison — never the assertion itself. Credo's `NoAssertions` check is purely syntactic and flags tests whose asserts live inside helpers, so:
   - Helper returns a value → test asserts on it: `task = upsert_with_priority!(ctx, params); assert priority_value(task) == "High"`.
   - Helper does matching → return a boolean via `match?/2` and assert at the call site: `assert auth_error?(conn, query, vars, "tasks")`.
   - Bang helpers (`!`) can pattern-match internally and crash loudly, but every check the test cares about still needs a visible `assert`/`refute` at the call site.

# Jump-specific conventions

- Test module choice:
  - `use Jump.DataCase, async: true` — context, schema, pure business logic
  - `use JumpWeb.ConnCase, async: true` — HTTP, controllers, LiveView
  - `use JumpWeb.E2ECase, async: true` — Playwright
  - `use JumpWeb.ChannelCase` — Phoenix channels
- Build data with `Jump.Factory.create/2` — never `Repo.insert!/1` in a test.
  - Pass only overrides the test actually reads. Let `example_data/0` supply the rest.
  - `create(Meeting, user_id: user.id)` — not `create(Meeting, topic: "...", started_at: ...)` unless the test inspects those fields.
- LiveView tests: PhoenixTest (`visit/2`, `fill_in`, `click_button`, `await_has`, `await_gone`). Never `live/2`. Never `Process.sleep/1` — use `AssertionHelpers.await!/1` for non-DOM polling.
- Add `data-qa="..."` only when text/id selectors can't disambiguate.
- Mocks: Hammox (`Mock.expect/3`). No hand-rolled stubs.
- Colocate: `_test.exs` lives next to the source module (e.g., `lib/jump/meetings/meetings_test.exs`), not under `test/`.
- Scope every query by `account_id` in both code and assertions.

# Helper escalation ladder

Before adding a helper to a test file, grep sibling tests and `test/support/` — if it exists or will likely be reused, place it in the right home from the start.

| Duplication | Home | Example |
|---|---|---|
| 2+ test files, domain-specific | `test/support/<domain>_helpers.ex`, imported via case module | `auth_helpers.ex`, `llm_v2_helpers.ex`, `salesforce_api_client_helpers.ex` |
| Same schema defaults rebuilt repeatedly | Extend that schema's `example_data/0` | `lib/jump/**/<schema>.ex` |
| Cross-cutting "build a whole tenant" recipe | Function in `Jump.Factory` | `lib/jump/factory.ex` |
| Large JSON/XML/WBXML payload | File under `test/fixtures/<integration>/`, read by path | `test/fixtures/salesforce/`, `test/fixtures/docusign/` |

Existing shared helpers to check before writing new ones:
`assertion_helpers`, `auth_helpers`, `autodiscover_helpers`, `cache_helpers`, `ecto_helpers`, `emoney_helpers`, `enterprise_oauth_helpers`, `helpers`, `llm_v2_helpers`, `otel_test_helpers`, `outlook_test_helpers`, `product_helpers`, `redis_helpers`, `redtail_api_client_helpers`, `salesforce_api_client_helpers`, `saml_helpers`.

# Anti-patterns

- Duplicating setup across `describe` blocks instead of lifting it.
- Reimplementing something already in `test/support/`.
- Creating a new `*_helpers.ex` for a one-file helper; keep it private first.
