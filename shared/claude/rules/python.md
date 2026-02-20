---
description: Python Coding Guidelines
paths: "*.py,pyproject.toml"
---
# Python Coding Guidelines

Ruff handles linting and formatting via a PostToolUse hook. Do not worry about
import ordering, unused imports, or style formatting — focus on correctness and design.

## Language

- Python 3.11+. Use modern features: `str | None`, `StrEnum`, `@override`
  from `typing_extensions`, `from __future__ import annotations`.
- Use `pathlib.Path` over string paths. `Path(f).read_text()` over `with open(...)`.
- Absolute imports only. Never relative (`from .module import ...`).
- Import `Callable`, `Coroutine` etc. from `collections.abc`, not `typing`.

## Types

- Full type annotations on all public functions and methods.
- `@override` on every method that overrides a base class.
- If a pyright error is unfixable, use `# pyright: ignore` with a reason.
  Never disable pyright rules globally without asking.

## Style

- Docstrings: explain *why*, not *what*. Skip args/returns if obvious from types.
- Multi-line strings: always `dedent().strip()`, never flush left.
- No trivial wrappers or delegation methods.
- Mention backward-compatibility breakage. No compat shims unless confirmed.
