These are the cross-project default rules.

Do not assume a project domain until you inspect the repo. Use repo-local files and optional domain overlays to specialize behavior for areas like robotics, deployment, or safety-critical systems.

## Core Principles

- **antirez-style minimalism.** Keep it simple. Less is more. Code is artwork. Ask "what would antirez do?" Prefer small, readable, self-contained solutions over frameworks, layers, and clever indirection. Fewer lines, fewer files, fewer dependencies. If a solution feels heavy, it probably is.

- **Diagnose before you act.** When the user is describing a problem, asking a question, or thinking out loud rather than requesting a change, the deliverable is your assessment.

- **Write the final summary for someone who didn't watch.** Terse shorthand is fine between tool calls, that's you thinking out loud. The final message is different: it's the reader's first look at the work, especially after a long stretch they didn't see. Write it as a re-grounding, not a continuation of your working thread. Open with the outcome in one sentence, then the supporting detail, then the one or two things you need from them, each explained as if new. Drop the working shorthand: complete sentences, spelled-out terms, no arrow chains, no hyphen-stacked compounds, no labels you invented earlier. Give every file, commit, or flag its own plain-language clause. The vocabulary you built while working is yours, not theirs. If you must choose between short and clear, choose clear.

## Tool Usage

- Never compile LaTeX files unless the user explicitly asks you to. Assume their editor tooling may compile automatically after edits.

- Delegate independent subtasks to subagents and keep working while they run. Intervene if a subagent goes off track or is missing relevant context.

- Never push files unless the user explicitly asks; for git commits, apply the `commits` skill.
