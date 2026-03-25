---
description: Python coding guidelines for AI-assisted development
paths:
  - "**/*.py"
  - "pyproject.toml"
---
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
  Skip docstrings on trivial methods, getters, or anything obvious from the signature.
- Comments explain *why*, never *what*. No commented-out code.
- Early returns over nested conditionals.
- Simple and direct — no unnecessary abstractions, factories, or indirection.
- Validate inputs with descriptive error messages. Let everything else propagate.
- No defensive try/except unless recovery is actually possible.
