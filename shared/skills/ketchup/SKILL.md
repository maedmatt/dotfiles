---
name: ketchup
description: "Catch the user up on agent work since they handed it off: what was done, why, and what waits on them. Use for /ketchup."
disable-model-invocation: true
---

# Ketchup

Give the user back the thread of multi-turn work they lost track of: what was done since they handed it off, why, and what waits on them, so they can steer it. A catch-up is not a one-shot answer: leave out commands, diffs, and parameter values unless a decision rests on one.

`/ketchup page` always writes the page. Any other text after `/ketchup` is a question to answer inside the catch-up.

## Your role

- **Single agent:** you have no workers, and no other agent briefed you. Follow the general rules.
- **Lead:** you started or briefed other agents, your workers. Follow the general rules, then "Lead". If another agent started you or gave you your task, name it as your parent lead in your first line. An agent that only passed on a message from the user, or asked you for something, is not your lead.
- **Worker:** another agent gave you your task (your first prompt starts with `[from <name>]` or points to a brief from another session), and you have no workers. Follow "Worker".

## General rules

**Hand-off.** Cover the work since the user's hand-off: their last message that set the work's goal or direction and left it to the agents, such as a brief, a new task, a decision that started a new stretch of work, or "handle this overnight". Messages the user sent while the work ran (answers to questions, short notes, corrections) are not the hand-off; they go under "What you said during the work", each with what came of it. If an earlier catch-up covers part of that span, read its content file, keep its open items, and mark what is new since then, but still restate the goal. Name the hand-off by its time and words, and give the current time.

Agents that use `herdr agent prompt` are logged as the user. A message is an agent's when it starts with a sender tag (`[from <name>]`, `[hand-in] <path>`, "Message from ..."), reads as a structured report, or is a peer message, task notification, or subagent hand-back. The user writes casually, with typos and speech-to-text phrasing; when both typed into one message, split it. Assume the user remembers the end goal, but not each workstream's goal, the names you coined, or anything after the hand-off.

**Gather, read-only.** Except for the page, change nothing: answer no dialog, start or stop no agent or job, edit no code, move no hardware. Collect what happened since the hand-off: your turns, the user's messages, messages from other agents, reports, commits, and the images, videos, and plots made. A file the user has not seen counts as new. Check every state now, not from memory, check each number against its source, and write "unknown" for what you cannot see. Add resources only when they matter: subscription limits and their resets, and the user's share of the cluster, which is free to use but where the user should not be the top user.

**Sort** what you found:

- **Needs you:** open calls only the user can make: a choice, an approval, an irreversible action, access you lack, a step in the real world. Include open ones from before the hand-off. Merge duplicates, drop stale ones, never invent one. A question the user already answered is not open: it goes under "What you said during the work".
- **Done in your name:** what was done without the user's explicit approval: terms accepted that `references/licences.md` in the `machines` skill does not list, data sent to a third party, deletions, a history rewrite, a rule added to their instructions, a decision taken while they were away, their words passed on more strongly. Say how to undo each, or that it cannot be undone.
- **What you said during the work:** each of the user's messages since the hand-off, and what came of it.
- **Changed beliefs:** earlier claims since corrected, and what was decided on them.
- **Workstreams:** one per goal the user set: the goal in their words, each step since the hand-off with what it found and why the next one followed, and how far it is from done, measured against the test for done when one exists.

**Reply** in this order, since the user may stop reading after the first items:

1. One line: what waits on the user, the hand-off, the current time.
2. Needs you, numbered so the user can answer "1 yes, 2 no". For each: what the thing is, when the user may not know; the question; your pick and the fact it rests on; every option weighed, including leaving it as it is, with what each gets and costs. Say what waiting costs only when it is more than a delay. When one call covers many items, ask once and list the items, riskiest first. A step in the real world is one item: what and why, not how.
3. Done in your name.
4. What you said during the work, one line each, only where the outcome is new to the user.
5. Workstreams: the goal, what came of it and why, how far from done, and what happens next without the user.
6. Changed beliefs and resources, only what matters now.
7. The page path.

Aim for about two minutes of reading; move depth to the page, never drop an item.

**Words.** The user knows their field and their project: infer what they know from the project and what they have worked on, and do not explain basics. Explain what they have not seen; they can ask about the rest. Use [`/bro`](../bro/SKILL.md)'s voice: plain words, short sentences with one idea each.

- For each item, say what happened, why, and what it means for the user's goal.
- A name made up during the work (job numbers, gate names, worker nicknames, finding IDs) gets what it is where it first appears, or disappears. On the page, these names go in the glossary.
- A number gets what it is compared with: before and after, or the target.
- Give each result its source and strength (real or simulated, offline or on the robot, runs or seeds, held-out or not, new or already published) and whether it supports the claim the user cares about.

Not: "Packet B8 for job 4471 is drafted; gate G2 stays closed until the reviewer signs off." But: "The check that decides whether the new data can be used is written but has not run yet. It runs when the data job finishes, around 12:30, and a second agent then reviews its result."

**The page.** Write an HTML page when there are images, videos, or plots, when more than two workstreams moved, when the hand-off is more than a day old, or when the user asks. Do not write HTML or CSS. Write the content as JSON in the shape of `assets/example.json` in this skill's folder, then run `python3 <this skill's folder>/scripts/render_page.py <content.json> --out <page.html>`. The script fixes the layout, the order, and the colors (amber: needs you; red: cannot be undone, blocked, failed; green: done; blue: running; grey: idle or unknown), checks that media files exist, and prints a warning for each missing field: fix them and run it again.

Save the page as `~/.local/state/ketchup/<project>/<YYYY-MM-DD_HHMM>-<your agent name>.html`, and its content file next to it with the same name and `.json`. `<project>` is your Herdr workspace's label (`herdr workspace get "$HERDR_WORKSPACE_ID"`), or outside Herdr your git repository's name. Reference media by absolute path, and open the page (`xdg-open` on Linux, `open` on macOS). Before writing, read the latest content file in that folder, so nothing it left open is dropped without a word.

## Lead

Load the `herdr` skill. Your workers are the agents you started or briefed; find them in your tool history. In addition to the general rules:

- For each worker, read its state, recent output (`herdr agent get`, `herdr agent read`), branches, and reports (in `~/.cache/agent-reports/<working folder name>/`). Flag a worker that finished without reporting, waits at a dialog or its own approval gate, crashed, or is still running, with when it should finish.
- Collect Needs you from every worker and merge duplicates across them. In each workstream, say which worker handed what to whom.
- After the workstreams, list the workers: name, task, state, last result. Give a renamed worker's earlier name once.
- A worker that runs its own workers is a lead you spun off: give its last hand-in and its state, and tell the user to run `/ketchup` there for the detail.
- Agents you did not start count only for what they told you.

## Worker

Say first that you are a worker, not the lead, and name the lead (its Herdr name, workspace, tab, and pane, from `herdr agent list`) so the user can run `/ketchup` there. Then catch up on your own task in a few lines, since the user's last hand-off to you or your task's start, and put first any question the lead may not have passed on. Write no page.
