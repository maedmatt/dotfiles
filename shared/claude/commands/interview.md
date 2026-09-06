---
allowed-tools: AskUserQuestion, Read, Glob, Grep, Write, Edit
argument-hint: [plan-file]
description: Interview to flesh out a plan/spec
---

Here's the current plan:

@$ARGUMENTS

Turn this plan into a spec by interviewing me. The spec is done when someone could build from it without asking me anything, so the questions worth asking are the ones the plan leaves open and I have probably not considered yet: implementation choices, UI and UX, edge cases, tradeoffs, what could go wrong. Anything the plan already answers is not worth asking. Use an ask-question tool if one is available.

Keep interviewing, round after round, until nothing is left open, then write the spec back to `$ARGUMENTS`.
