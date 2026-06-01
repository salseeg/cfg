---
name: spawn-here
description: Open a new terminal tab and join this Claude Code session in it. Use when the user wants a second Claude terminal, wants to split work, or says "spawn here".
allowed-tools: Bash, Agent
---

# Spawn a new terminal with Claude attached to this session

When this skill is invoked, do the following:

1. Read `CLAUDE_CODE_SESSION_ID` env var and the current working directory — this MUST happen in the main context (the env var is only available here).
2. Delegate the actual spawn to a subagent (to keep the main context clean). Pass the session ID and working directory as explicit values in the agent prompt.

Example:

```
Agent({
  description: "Spawn terminal",
  prompt: "Run this command without asking for confirmation:\n\nspawn-term --exec bash -c \"claude --resume <SESSION_ID>\"\n\nReport whether it succeeded.",
})
```

Replace `<SESSION_ID>` with the actual value read in step 1.

3. Report that a new terminal was spawned and joined this session. One sentence is enough.
