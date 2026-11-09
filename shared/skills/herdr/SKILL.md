---
name: herdr
description: "Control Herdr, the terminal multiplexer that runs coding agents in panes. Load it before you start, brief, wait for, or message another agent, or read or control another pane. Requires HERDR_ENV=1."
---

# Herdr

Run `herdr --skill` and follow what it prints; it always matches the installed version. The rules below add to it and win where they differ.

## Leading workers

The user's messages and the text an agent sends with `herdr agent prompt` land in the same prompt and look the same in the logs. So:

- Start every prompt you send with `[from <your agent name>]`. When you pass on the user's words, quote them; never make them stronger.
- Before you start workers, load the `agent-usage` skill and run `agent-usage advise --size <task size> --agent --short` once for the whole batch. Start each worker with the harness and model it suggests: its launch command `<harness> <arguments>` becomes `herdr agent start <name> --kind <harness> --pane <pane id> -- <arguments>`. Skip this step when `agent-usage` is not installed.
- Run that check again at each hand-in, and at least once an hour while workers run. Your own session counts: when it runs on a subscription the advice says to save, do only coordination yourself, and give implementation, test runs, and comparisons to workers.
- After you start or prompt a worker, run `herdr agent wait <name>` in the background. When the worker stops, read its output and pass its questions to the user.
- Name each worker after its workstream, and keep that name.
- Start each worker in its own tab in your workspace, labeled with the worker's name. Leave creating, moving, and splitting workspaces to the user.
- When a workstream grows into its own line of work, hand it to a new lead: brief it like a worker, and it starts its own workers. Tell the user where it runs.
- For licences, EULAs, and dataset terms, follow `references/licences.md` in the `machines` skill, and ask the user only about terms it does not list. Leave other dialogs meant for the user, such as a payment or a login, waiting, and tell the user.
- Brief every worker with these lines, since a worker may never load this skill. Replace `<project>` with the name of your working folder.

  > Start every message you send to another agent with `[from <your agent name>]`. When you finish, write your report to `~/.cache/agent-reports/<project>/<your agent name>-<YYYY-MM-DD_HHMM>.md` and send `[hand-in] <absolute path of the report>` to the agent that briefed you. Put first what needs the user, what you did in their name, and what contradicts an earlier report. For licences and terms, follow `references/licences.md` in the `machines` skill, and stop and report terms it does not list.
