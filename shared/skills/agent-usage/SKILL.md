---
name: agent-usage
description: "Check the user's AI subscription headroom, and pick a harness and model, before heavy work or before starting other agents, so quota is used before it resets and the user's reserve stays untouched. Requires the agent-usage command."
---

# agent-usage

If `command -v agent-usage` finds nothing, the tool is not installed on this machine: skip this skill.

Run `agent-usage --skill` and follow the instructions it prints. The tool ships its skill inside the program, so the printed instructions always match the installed version.
