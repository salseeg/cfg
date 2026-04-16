---
name: pr-description
description: Use when the user asks to summarize branch changes, describe a PR, or prepare a PR description. Also use when creating a PR with gh pr create.
---

# PR Description

Generate a concise PR description from branch changes against main.

## Format

```
[Ticket Title](ticket-url) — brief context.

 - change one
 - change two
 - change three
```

## Rules

1. **Ticket link first** — always include the ticket/Notion link as a markdown link on the first line, followed by a short context phrase
2. **Bullet points only** — each bullet is one logical change, written in present tense lowercase (e.g., "adds...", "fixes...", "updates...")
3. **5 lines max** — collapse related changes into a single bullet; no sub-bullets unless truly necessary
4. **No implementation details** — describe *what* changed from a user/reviewer perspective, not *how* (no file names, no class names, no code)
5. **Dash separators** — if a bullet has a clarifying note, use an em dash (e.g., "works around LiveView bug — filter dropdowns now close on navigation")

## Ticket Discovery

1. Extract ticket ID from the current branch name (e.g., `agnt-125-some-feature` → `AGNT-125`)
   - Pattern: look for a prefix of letters followed by a dash and digits (e.g., `agnt-125`, `ENG-42`, `fix/plat-300-thing`)
2. If a ticket ID is found, try to resolve it in this order:
   a. **Linear MCP** — use the Linear MCP server tools to search for the issue by identifier (e.g., `AGNT-125`). Use the returned title and URL for the PR description header.
   b. **GitHub MCP** — if Linear MCP is not available or lookup fails, use the GitHub MCP server tools to search for a matching GitHub issue by the ticket ID.
   c. **Ask user** — if both MCP lookups fail or are unavailable, ask the user for the ticket link.
3. If no ticket ID found in branch name → ask the user for the ticket link

## Workflow

1. Run `git log main..HEAD --oneline` and `git diff main...HEAD --stat` to understand scope
2. Read the full diff with `git diff main...HEAD` if needed for context
3. Discover the ticket (see Ticket Discovery above)
4. Write description in the format above
5. Present to user for approval before using in `gh pr create`
