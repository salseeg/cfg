---
name: as-me
description: Review and improve changed Elixir files to match the user's coding style. Use when the user says "as me", "review as me", "fix as me", "clean up like I would", or wants changed files checked against their personal Elixir conventions. Runs test-writing rules on *.exs files and Elixir code style (elixir, elixir-functions, elixir-module) on *.ex files.
---

# As-Me: Apply Personal Code Style to Changes

Review changed Elixir files and apply the user's established coding conventions via subagents.

## Gather Changed Files

1. Collect changed files from **all available sources**, deduplicating:
   - Git staged files: `git diff --cached --name-only --diff-filter=ACMR`
   - Git unstaged files: `git diff --name-only --diff-filter=ACMR`
   - Any files mentioned in the current conversation context
2. Filter to only `.ex` and `.exs` files that exist on disk.
3. If the working directory is a monorepo with sub-projects (e.g. `chat/`, `platform/`, `toolbox/`), run git commands in each sub-project that is a git repo.

## Process Files

### For each `*.exs` file (tests) — run one subagent per file

Spawn a subagent with the **me-test-writing** skill instructions. The subagent prompt must include:

- The full content of the test file
- The skill instructions (reproduced below in the reference section)
- Instruction: "Review this test file and apply fixes directly. Keep test cases under 30-40 lines, extract common code to helpers, name helpers descriptively, place helpers after their usage site (or at file end if shared). Minimal comments."

### For each `*.ex` file (code) — run one subagent per file

Spawn a single subagent per file that applies **all three** Elixir code skills together. The subagent prompt must include:

- The full content of the code file
- The combined skill instructions for: **elixir**, **elixir-functions**, **elixir-module**
- Instruction: "Review this Elixir module and apply fixes directly. Check for: assertive code over defensive programming, proper function structure (pipe/select/railway shapes, 30-40 line max), module organization (300-line limit, correct split axis if needed), idiomatic patterns. Fix issues in place."

## Execution

- Run all subagents in parallel (one per file).
- Each subagent reads the file, applies the relevant skill rules, and edits the file directly.
- After all subagents complete, summarize what was changed: list each file and the changes made.

## Reference: Skill Instructions to Include in Subagent Prompts

When spawning subagents, read the actual skill files to get current instructions:

- **me-test-writing**: `/home/salseeg/.claude/skills/me-test-writing/SKILL.md`
- **elixir**: `/home/salseeg/.claude/skills/elixir/SKILL.md`
- **elixir-functions**: `/home/salseeg/.claude/skills/elixir-functions/SKILL.md`
- **elixir-module**: `/home/salseeg/.claude/skills/elixir-module/SKILL.md`
