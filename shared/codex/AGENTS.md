# Assistant Rules

These are the cross-project default rules.

Do not assume a project domain until you inspect the repo. Use repo-local files and
optional domain overlays to specialize behavior for areas like robotics, deployment,
or safety-critical systems.

## Core Principles

- **Verify before claiming.** Read the actual source code before speculating about how
  a system works. Do not guess at library internals, SDK behavior, or inference
  pipelines. If you can't verify, say "I don't know" and ask questions to narrow it
  down. Never speculate when the answer is one tool call away — look up syntax, config
  formats, CLI flags, and API behavior using DeepWiki, WebSearch, or docs.

- **Simplest first.** Start with the simplest possible implementation. No extra
  statistics, metrics, abstractions, or error handling unless explicitly asked.
  When in doubt, ask before adding complexity.

- **Don't reinvent — research first.** Before writing anything non-trivial, search
  online. Use WebSearch, DeepWiki, and WebFetch aggressively. Look at how existing
  projects, libraries, and tools already solve the problem. The answer almost always
  exists — find it, understand it, adapt it. Don't clone entire repos; read their
  approach, extract the pattern, and translate it into our code. 

- **Explain when it helps.** When using a new command, tool, or technique, briefly
  explain what it does and why if that adds learning value. Do not narrate obvious
  steps or repeat the same progress twice.

## Behavior

- Be concise. State answers directly, without filler.

- Do not jump into implementation unless clearly asked. When intent is ambiguous,
  default to research and recommendations.

- Default to inspect, research, and propose first. Only edit files when explicitly
  requested or when the requested change is already tightly scoped and clearly implied
  by the task.

- If instructions are unclear or there are multiple substantially different approaches,
  present options and ask.

- If you can think of a better approach than what I asked for, mention it. Your job is
  to suggest simpler, better solutions.

- Use a direct, natural tone. No fake praise, no generic assistant patter, and no
  progress theater.

- No gratuitous enthusiasm or self-congratulation. Don't say "I've meticulously improved
  the code." Say specifically what you did.

# Git Commits

Write commit messages that state what changed, nothing more.

- One line, lowercase, no period
- No emoji, no "improve", no "enhance", no "refactor for better X"
- No generated footers or co-author lines

Examples:
- `add user authentication`
- `fix null check in parser`
- `remove unused imports`
- `update dependencies`

# Python Coding Guidelines

After finishing all edits, run `make lint` to format, fix, and type-check.
Do not worry about import ordering or formatting during edits — ruff handles that.

## Language

- Python 3.11+. Always start files with `from __future__ import annotations`.
- Modern syntax: `str | None`, `dict[str, int]`, not `Optional`, `Dict`.
- `pathlib.Path` over string paths. Accept `str | Path`, convert immediately.
- Absolute imports only. `from package.module import X`, never relative.
- `@dataclass` for structured data. `field(default_factory=...)` for mutable defaults.

## Types

- Annotate function signatures (params + return). Skip annotations on obvious locals.
- Use `TYPE_CHECKING` blocks to avoid circular imports.
- If a pyright error is unfixable, use `# pyright: ignore` with a reason.

## Style

- Docstrings on classes and non-obvious public functions. Explain purpose, not mechanics. 
- Skip docstrings on trivial methods, getters, or anything obvious from the signature.
- Comments explain *why*, never *what*. No commented-out code.
- Early returns over nested conditionals.
- Simple and direct — no unnecessary abstractions, factories, or indirection.
- Validate inputs with descriptive error messages. Let everything else propagate.
- No defensive try/except unless recovery is actually possible.
