---
name: sync
description: Sync session context to memory and project files
allowed-tools: Bash(uv run *), Read, Glob, Grep
---

# Sync

Sync the current session's context to persistent files for cross-session continuity.

## Tool rules

**Never** use Bash when a dedicated tool exists. No exceptions:
- `ls`, `find` → **Glob**
- `grep`, `rg` → **Grep**
- `cat`, `head`, `tail` → **Read**

Bash is only for the extraction script (`uv run`).

## Step 1: Gather context

Run the extraction script to get the full conversation transcript:

```bash
uv run ~/.claude/skills/sync/scripts/extract-session.py
```

This outputs only user messages and Claude text responses, stripped of tool calls,
images, progress messages, and system reminders.

Also read the current state of these files (if they exist):
- MEMORY.md at the auto memory path shown in your system prompt
- CLAUDE.md at the project root `.claude/CLAUDE.md`
- The global rules at `~/.claude/rules/` (to avoid duplicating what's already there)

## Step 2: Update MEMORY.md

Write what future-you needs to pick up where you left off:

- Key decisions made and why
- Current state of in-progress work (what's done, what's next)
- Patterns, conventions, or gotchas discovered
- Important file paths or architecture insights
- Anything you had to figure out that wasn't obvious

Do NOT include:
- Generic programming knowledge
- Things already documented in CLAUDE.md or rules/
- Verbatim conversation — synthesize, don't copy

Keep it under 180 lines (auto-load limit is 200). Organize by topic, not
chronologically. Merge with existing content and remove outdated entries.

## Step 3: Update CLAUDE.md (only if needed)

Only update if project structure, conventions, or constraints have genuinely
changed. Most sessions won't need CLAUDE.md changes.

Examples of when to update:
- New symlink, hook, or script added
- Platform constraint discovered
- Workflow change that affects future sessions

## Step 4: Rule suggestions

Review the conversation for recurring patterns about how the user prefers to
work, communicate, or be assisted. Surface anything that should become a
permanent rule in `~/.claude/rules/general.md`.

Present suggestions as a short list. For each:
- The proposed rule (one or two sentences)
- Why — what happened in the conversation that revealed this

Do NOT edit general.md directly. Only suggest. The user decides what to add.

## Step 5: Summary

Show a brief summary:
- What changed in MEMORY.md
- What changed in CLAUDE.md (if anything)
- Rule suggestions (if any)
