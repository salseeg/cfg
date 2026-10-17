---
name: wizard
description: "Think-then-do: sends the task to Opus 5.5 for strategic analysis and a high-to-mid detail implementation plan, then the current model implements it. Use when facing non-trivial architecture, design, or multi-step implementation decisions."
---

# /wizard

Delegate strategic thinking to Opus 5.5, get back implementation intel, then execute.

## Usage

```
/wizard <task or question>
```

The argument is everything after `/wizard`. If none is provided, ask the user what they want the wizard to think about.

## Workflow

### Step 1 — Gather context

Before calling the wizard, collect context it will need. Run these read-only commands and note the output:

- Current working directory
- `git diff --stat` if in a git repo (what's in flight)
- Any files or errors the user referenced in conversation

Also note what project this is in (check CLAUDE.md) and any relevant architecture info you already know.

#### Graphify context (if available)

Check whether `graphify-out/graph.json` exists in the working directory. If it does:

1. Run `graphify query "<the user's task>"` to get a scoped subgraph with relevant modules, dependencies, and relationships.
2. If the task involves connecting two parts of the system, also run `graphify path "<A>" "<B>"`.
3. Include the graphify output in the wizard prompt's **Context** section — it gives the wizard architectural orientation that raw grep cannot.

If `graphify-out/graph.json` does not exist, skip this — do not install or run graphify just for the wizard.

### Step 2 — Call Opus 5.5 via CLI

Use `claude --model claude-opus-5-5 --print` via Bash. This bypasses the Agent tool's model alias limitation (where `"opus"` resolves to the current session's model, not Opus 5.5).

#### CLI flags

```bash
claude --model claude-opus-5-5 \
  --print \
  --allowedTools "Read Bash(find *) Bash(grep *) Bash(git log *) Bash(git show *) Bash(git diff *) Bash(wc *)" \
  --permission-prompts none \
  --no-session-persistence \
  < "$SCRATCHPAD/wizard_prompt.txt" \
  > "$SCRATCHPAD/wizard_output.txt" 2>&1
```

Flag rationale:
- `--allowedTools` — gives Opus 5.5 **read-only file access** so it can explore the codebase itself. No need to embed file contents in the prompt.
- `--permission-prompts none` — anything not in `--allowedTools` is auto-denied (safe: no writes, no edits).
- `--no-session-persistence` — don't clutter session history with throwaway wizard calls.
- Redirect to file — output is captured for reliable reading regardless of size.

#### Building the prompt

Write the full prompt to `$SCRATCHPAD/wizard_prompt.txt`. The prompt MUST include:

1. **The task** — what the user asked for
2. **Context** — working directory, project structure summary, relevant file paths, any errors or constraints from the conversation. You no longer need to embed file contents — the wizard can Read files itself. But DO mention which files are relevant so it knows where to look.
3. **Instructions** — the full block below (copy it into the prompt verbatim):

```
You are a strategic thinker. Your job is to investigate the codebase, think deeply, and return a structured implementation brief. You do NOT edit files or implement anything.

You have read-only access to the codebase via Read and Bash (find, grep, git log/show/diff, wc). Use them to explore relevant files before forming your plan.

Workflow:
1. Read relevant source files, grep for symbols, check tests
2. Reason about the problem — tradeoffs, edge cases, gotchas
3. Produce your implementation brief

Your final output MUST be a structured brief in this exact format:

## Goal
One sentence.

## Approach
The chosen strategy. Why alternatives were rejected (name them).

## Steps
Ordered list. Each step has:
- File path (exact, from repo root)
- What to change: function/module name, line range if known
- The change: what to add, modify, or remove — be specific enough that an implementer doesn't need to re-derive your reasoning
- Why this step matters

## Gotchas
Things to watch out for during implementation. Hidden coupling, ordering dependencies, config that needs updating.

## Verification
How to confirm the change works — specific test commands, things to check manually.

Keep the brief high-to-mid detail: enough that a competent developer can implement without guessing, but don't write the actual code. Name the functions, describe the logic, specify the signatures — but leave the implementation to the caller.
```

4. **Constraint** — "Report your brief in under 4000 words. Be dense, not verbose."

#### Running the wizard

Run the Bash command with `run_in_background: true` and `timeout: 600000` (10 minutes). This way:
- The user is **not blocked** — they can keep chatting while the wizard thinks.
- You get **automatically notified** when it completes.
- No silent 5+ minute wait.

```
Bash({
  command: "claude --model claude-opus-5-5 --print --allowedTools 'Read Bash(find *) Bash(grep *) Bash(git log *) Bash(git show *) Bash(git diff *) Bash(wc *)' --permission-prompts none --no-session-persistence < $SCRATCHPAD/wizard_prompt.txt > $SCRATCHPAD/wizard_output.txt 2>&1 && echo 'WIZARD_DONE'",
  run_in_background: true,
  timeout: 600000
})
```

Tell the user: "Wizard is thinking (Opus 5.5). You'll be notified when it's done — feel free to keep working."

#### Reading the result

When notified of completion, read `$SCRATCHPAD/wizard_output.txt` with the Read tool. This is the implementation brief.

### Step 2.5 — Save and present the brief

#### Persist the brief

Save the wizard output to a durable location so future conversations can reference it:

```
$PROJECT_ROOT/wizard-briefs/<timestamp>-<slug>.md
```

Where `<timestamp>` is `YYYY-MM-DD` and `<slug>` is a short kebab-case label derived from the task (e.g. `2026-10-17-vouch-token-refactor.md`). Create `wizard-briefs/` if it doesn't exist. Add a YAML frontmatter header:

```markdown
---
task: "<the user's original request, one line>"
model: claude-opus-5-5
date: <YYYY-MM-DD>
status: pending
---
```

Set `status` to `pending` on creation. Update it to `implemented` or `rejected` after Step 3.

#### Surface to the user

Publish the brief as an Artifact so the user can review it before any code is written. Tell the user:

> "Here's the wizard's plan. Review it — I'll implement once you give the go-ahead, or tell me what to change."

**Do not start implementing until the user approves.** If the user says nothing and continues with an unrelated message, treat the brief as parked — don't implement silently.

### Step 3 — Implement

Once the user approves the brief:

1. Read the brief carefully — it is your implementation plan
2. If the brief has obvious gaps or you disagree with the approach, tell the user before implementing
3. Implement the steps yourself
4. Follow project code style (CLAUDE.md, STYLE.md)
5. Run tests and formatters as the brief's verification section says
6. Update the brief's `status:` frontmatter to `implemented` (or `rejected` if the user declined)
7. Report what you did — one short summary

## Key rules

- The thinker thinks, you do. The CLI call has read-only access — it never edits files.
- Always use `claude --model claude-opus-5-5 --print` — this is the only way to guarantee Opus 5.5.
- The wizard has `--allowedTools` for file access — mention relevant paths in the prompt but don't embed file contents.
- Run with `run_in_background: true` so the user isn't blocked.
- For trivial tasks, tell the user it's not worth a wizard call and just do the work.
- If the wizard returns nothing useful, tell the user — don't silently ignore the failure.
- **Always present the brief to the user before implementing.** Wait for approval.
- **Always save briefs** to `wizard-briefs/` — they're a persistent record of architectural decisions.
- **Use graphify** when `graphify-out/graph.json` exists — it gives the wizard much better codebase orientation than blind grepping.
