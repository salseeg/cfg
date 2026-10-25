---
description: Pick up unblocked GitHub issues and implement them, one PR per issue. Works through the dependency tree created by /bp-spec-to-issues, creating branches and PRs in the appropriate repo.
allowed-tools: Bash, Read, Write, Edit, Agent, AskUserQuestion, WebFetch
---

# Implement Issues

Pick up unblocked issues from a spec's dependency tree and implement them, creating one PR per issue. Uses a fork to keep the main context lean — all heavy implementation work happens in the fork, and only a summary returns.

## Input

The user may provide:
- A spec label (e.g., `spec:vouch-expiry`) — find all issues with that label
- Specific issue numbers (e.g., `#101, #103`)
- Nothing — find all `ready` issues in Buckitup-chat/chat

## Procedure (Coordinator)

The coordinator runs in the main context. It is lightweight — no file reads, no test runs, no git operations beyond what's listed here.

### 1. Load session journal

Check the scratchpad directory for a journal from a prior run:

```
<scratchpad>/bp-implement-journal.md
```

If it exists, read it. It contains a summary from the previous run (issues implemented, PRs created, issues unblocked). This is the fork's starting context.

### 2. Fork the implementation work

Launch a single fork (`subagent_type: "fork"`) with a directive to execute one implementation cycle. The fork inherits full context including these instructions.

The fork directive must include:
- The journal content (quote it verbatim if it exists, or say "No prior journal — fresh start")
- The user's input (spec label, issue numbers, or "find all ready+go issues")
- The instruction: **"Execute one implementation cycle per the Fork Instructions below. End with the journal summary in the exact format specified."**

Wait for the fork to complete.

### 3. Write journal

Take the fork's summary and overwrite `<scratchpad>/bp-implement-journal.md` with it. Always overwrite, never append — the journal holds only the latest run's state.

### 4. Stop

Do not continue or ask follow-up questions. The journal is the final output of this run.

---

## Fork Instructions

These steps are executed by the fork, not the coordinator. The fork does all heavy work: git, file editing, tests, GitHub API calls. End with a structured summary.

### Step 0. Check for PR feedback

Before picking up new work, check all open PRs for unaddressed review feedback:

```bash
for repo in chat chat-frontend; do
  gh pr list -R "Buckitup-chat/$repo" --author "@me" --state open --json number,title,headRefName,url
done
```

For each open PR, check if there are review comments newer than the last commit:

```bash
LAST_COMMIT_DATE=$(gh pr view <number> -R Buckitup-chat/<repo> --json commits --jq '.commits[-1].committedDate')
gh api "repos/Buckitup-chat/<repo>/pulls/<number>/comments" --jq "[.[] | select(.updated_at > \"$LAST_COMMIT_DATE\")] | length"
gh api "repos/Buckitup-chat/<repo>/pulls/<number>/reviews" --jq "[.[] | select(.submitted_at > \"$LAST_COMMIT_DATE\" and .state != \"APPROVED\" and .state != \"PENDING\")] | length"
```

If there is unaddressed feedback:

1. Switch to that branch, pull latest
2. Read the feedback (inline comments + review body)
3. Fix each point. Run format, credo, tests.
4. Commit as a new commit (never amend), push
5. Return to main

### Step 1. Find implementable issues

```bash
# By spec label — requires both `ready` and `go`
gh issue list -R Buckitup-chat/chat --label "spec:<slug>" --label "ready" --label "go" --state open --json number,title,labels,body

# Or all approved issues
gh issue list -R Buckitup-chat/chat --label "ready" --label "go" --state open --json number,title,labels,body
```

If no `ready` + `go` issues exist, check if any `blocked` issues have had their dependencies merged. For unblocked ones: remove `blocked`, add `ready`. They still need `go` from the user.

If nothing is implementable, skip to the summary.

### Step 2. Pick the next issue

Priority:
1. Lower layer number first
2. Prefer issues that unblock the most downstream work
3. User-specified issue numbers override priority

Skip issues already marked as completed in the journal from the coordinator.

Read the full issue body:
```bash
gh issue view <number> -R Buckitup-chat/chat
```

### Step 3. Determine target repo

From the issue title prefix:
- `[chat]` → `chat/`
- `[platform]` → `platform/`
- `[toolbox]` → `toolbox/`
- `[frontend]` → `chat-frontend/`

### Step 4. Create a branch

```bash
cd <repo>/
git checkout main
git pull origin main
git checkout -b <issue-number>-<short-slug>
```

### Step 5. Implement

Follow the issue's scope and acceptance criteria:
- Read the relevant `CLAUDE.md` and `STYLE.md` for the target repo
- Run `graphify query` before exploring unfamiliar code
- Follow the 300-line file limit for chat
- Use pipelines, `then/2`, `tap/2`, `with` patterns per STYLE.md

Verify each acceptance criterion:
- `mix test <path>` or `make test`
- `mix format --check-formatted`, `mix credo --strict`

### Step 6. Commit and push

```bash
mix format
mix credo --strict
mix test <relevant_test_files>

git add <specific-files>
git commit -m "$(cat <<'EOF'
<descriptive message>

Closes #<issue-number>

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
git push -u origin <branch-name>
```

### Step 7. Create PR

```bash
gh pr create -R Buckitup-chat/<repo> \
  --title "<issue title>" \
  --body "$(cat <<'EOF'
## Summary
<what this PR does, 1-3 bullets>

Closes Buckitup-chat/chat#<issue-number>

## Acceptance criteria
- [x] criterion 1
- [x] criterion 2

## Dependencies
<which PRs must merge before this one, if any>

## Test plan
- [ ] <how to verify>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

### Step 8. Update issue labels

```bash
gh issue edit <number> -R Buckitup-chat/chat --remove-label "ready" --add-label "in-progress"
```

### Step 9. Unblock downstream

Check blocked issues whose dependencies are all closed/merged:
```bash
gh issue list -R Buckitup-chat/chat --label "blocked" --state open --json number,body
```

For unblocked ones: remove `blocked`, add `ready`. They still need `go`.

### Fork output

The fork's final message MUST be a structured summary in this exact format — nothing else:

```markdown
# Implement Issues — Session Journal
Updated: <timestamp>

## Completed
- #<num> — <title> — PR: <url> — <status: open|merged>

## Feedback addressed
- #<num> — <summary of changes>

## Unblocked (needs `go`)
- #<num> — <title>

## Still blocked
- #<num> — waiting on #<deps>

## Next up
- #<num> — <title> (ready + go)

## Notes
<anything unusual, decisions made, gotchas encountered>
```

Include ALL issues from the prior journal (carried forward) plus anything new from this cycle. Omit empty sections.

---

## Rules

- **One PR per issue. No exceptions.**
- **One issue per fork.** The fork implements exactly one issue (plus any PR feedback), then returns.
- **Don't over-implement.** Stick to the issue's scope.
- **Check before push.** `mix format`, `mix credo --strict`, relevant tests.
- When addressing PR feedback, create a new commit (never amend).
