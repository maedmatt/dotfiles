---
name: consolidate
description: "After a stretch of exploration (many iterations, one-off scripts, abandoned variants, several agents), keep only what the project needs: record what the experiments taught, delete what only served the search, and simplify what stays without changing behavior. Use for /consolidate."
disable-model-invocation: true
---

# Consolidate

Agents find a direction by trying many things: quick scripts, variants side by side, experiment folders, extra workers. Once the direction is clear, go back over the path and keep only what the project needs. A cleanup changes structure, never behavior.

## 1. Direction

State in one sentence what the kept path is and what was exploration. If the code, the notes, and the history do not make it obvious, ask.

## 2. Inventory

List the leftovers and classify each as **product**, **tool still in use**, **spent experiment**, or **unknown**. Look in three places:

- **In the repository:** one-off scripts, notebooks, experiment and cache folders, generated images and videos, stale notes, duplicate or long docs, dead code, unused options and flags, duplicate helpers, and functions above complexity 10 (the `cyclomatic-complexity` skill). Dead-code tools such as vulture or knip give candidates only: check each hit.
- **Around it:** worker branches and worktrees, agent reports in `~/.cache/agent-reports/`, idle Herdr panes and tabs, local servers and the ports they hold, scheduled wake-ups.
- **On other machines:** cluster files and jobs, checkpoints, datasets, experiment-tracking runs, and Docker images and containers on shared machines. The `machines` skill says what you may touch there.

Read `git status` and `git log` first: uncommitted changes, branches, and pushed history you did not make belong to someone else.

## 3. Rules

- **Structure only.** A behavior change, even a fix noticed on the way, goes in its own commit, labelled as such.
- **In a fork, clean only this project's additions.** Leave upstream code as it is, so later merges from upstream stay easy.
- **Findings first, then the code.** Before deleting a spent experiment, write its result in the project's notes, decision log, or research log, with the numbers and where they came from. Git keeps the code.
- **Docs:** the README says only what is validated and current. Keep each doc short enough that an outsider reads it in one go, and check it with `/unslop`.
- **Not yours, not without asking:** other agents' uncommitted work, other branches, pushed history, other users' files.
- **Small steps.** If a change cascades, revert it, note what it needs first, and do that first.
- **Don't over-clean.** A few deeper modules with small interfaces beat many tiny pass-through functions.

## 4. Approve before deleting

Show the inventory as a table, with the action you propose for each item, and delete nothing *unknown* or not yours without a yes. Anything outside the repository needs an exact list (path, size, what it is, why it can go, whether it can be rebuilt) that the user approves before anything is deleted. A checkpoint or dataset that stays in use keeps every file it needs to run, such as its configuration and normalization statistics, not only the weights.

## 5. Freeze behavior, in proportion

Before moving or deleting code, record the output of the commands people actually run (stdout, stderr, exit code, output files) once, on real inputs, and run the test suite. If two runs differ, mask the noise (paths, timestamps, seeds). After each step, rerun only what that step touched; at the end, rerun everything once. Match the effort to the code: a small tool needs a handful of commands, not every combination of options. Never check robot or hardware code by moving hardware: check it dry, and report it as not yet run on the robot.

## 6. Cut, then simplify

Delete spent experiments, abandoned variants, dead code, unused options, and stale docs. A script someone still runs moves to a clearly named place; one nobody runs goes. Then thin each entry point to a call or two into the module that owns the logic, merge duplicate helpers and pass-through layers, and split functions above complexity 10. Every output must match the frozen record: a difference is a bug in the cleanup, not a new baseline.

## 7. Workers and quota

Split the work by module, one worker per module with fixed interfaces between them, and keep one integration owner who runs the comparison. Before starting workers, follow the `agent-usage` skill. When your own session runs on a subscription it says to save, coordinate only, and let workers on the advised subscription make the edits and run the checks. Close the panes, servers, and worktrees you opened once they are done.

## 8. Close and report

Commit structure changes apart from behavior changes, following `/commits`, and push only when the user allows it. Report in the `ketchup` format, with its page for a large cleanup: what needs the user first (deletions waiting for approval), what was deleted and where its findings now live, what was kept and why, before and after numbers (files, lines, entry points, functions above complexity 10), and how behavior was checked.
