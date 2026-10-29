---
name: bp-day-summary
description: Summarize what the user accomplished since 3am (UTC+3) — i.e. since midnight UTC / start of day. Use when the user asks for a day summary or work recap.
allowed-tools: Bash, Read, WebFetch, WebSearch
---

# Day Summary

Generate a results-focused summary of what the user accomplished since 3am local time (UTC+3), i.e. since `$(date -u +%Y-%m-%d)T00:00:00Z` (start of day UTC).

## Data Sources

Gather data from ALL sources below. Run the independent commands as parallel tool calls within a single message rather than one at a time.

### 1. Local Git History (4 repos)

For each of `chat/`, `chat-frontend/`, `platform/`, `toolbox/` — run from the monorepo root `/home/salseeg/work/buckitUp`:

```bash
git -C <repo> log --all --since="$(date -u +%Y-%m-%d)T00:00:00Z" --author="salseeg\|sergey-lukianov\|Sergey\|Serhii" --format="%h %s (%ar)" --no-merges
```

If a repo has no commits in the window, skip it silently.

### 2. GitHub Activity

Fetch recent activity for both profiles using `gh`:

```bash
# PRs authored or updated
gh search prs --author=salseeg --updated=">=$(date -u +%Y-%m-%d)T00:00:00Z" --limit 20 --json title,url,state,updatedAt,repository
gh search prs --author=sergey-lukianov --updated=">=$(date -u +%Y-%m-%d)T00:00:00Z" --limit 20 --json title,url,state,updatedAt,repository

# Issues touched
gh search issues --involves=salseeg --updated=">=$(date -u +%Y-%m-%d)T00:00:00Z" --limit 20 --json title,url,state,updatedAt,repository
gh search issues --involves=sergey-lukianov --updated=">=$(date -u +%Y-%m-%d)T00:00:00Z" --limit 20 --json title,url,state,updatedAt,repository
```

Deduplicate results across both profiles. **Exclude** results from personal repos (`salseeg/*`) — only include activity in team/org repos (e.g. `Buckitup-chat/*`).

```bash
# PRs merged today in team repos, authored by others (i.e. PRs the user reviewed/merged)
gh api 'search/issues?q=type:pr+is:merged+repo:Buckitup-chat/chat+merged:>='"$(date -u +%Y-%m-%d)"'+-author:salseeg+-author:sergey-lukianov&per_page=20' --jq '.items[] | {title: .title, url: .html_url, author: .user.login}'
```

These are PRs the user merged from others. Credit them as "merged (by &lt;author&gt;)".

### 3. Fresh Logs

Check `/home/salseeg/work/buckitUp/fresh_logs/` for any files modified since midnight UTC:

```bash
find /home/salseeg/work/buckitUp/fresh_logs/ -type f -newermt "$(date -u +%Y-%m-%d)T00:00:00" -ls
```

If log files exist, read their contents (or tail the most recent ones) to extract notable events — firmware burns, deploy results, device activity, errors.

### 4. Working Tree State

Capture uncommitted work that represents in-progress results:

```bash
git -C chat status --short
git -C chat-frontend status --short
git -C platform status --short
git -C toolbox status --short
```

## Synthesis Rules

**Focus on RESULTS, not changes.** Ask: "What did the user accomplish?" not "What did the user change?"

- Group related commits into accomplishments (e.g., 5 commits about "Electric sync" → "Got Electric SQL sync reconnection working")
- If commit messages are terse, inspect the diff with `git -C <repo> show --stat <hash>` to understand impact
- Mention PRs by their outcome: opened, merged, reviewed — link them
- Mention issues by what happened: filed, closed, discussed
- Include firmware burns / deploys from fresh_logs as concrete outcomes
- Note in-progress work from dirty working trees as "currently working on"

## Output Format

```markdown
# Day Summary — <date range>

## Accomplished
- Result-oriented bullet points grouped by area
- Each bullet = one meaningful outcome
- Link PRs/issues where applicable

## In Progress
- Uncommitted work or open PRs still being worked on

## Device / Ops
- Firmware burns, deploys, device events from logs (if any)
```

Omit sections that have no content. Keep it concise — one screen max.
