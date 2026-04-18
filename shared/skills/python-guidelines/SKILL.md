---
name: python-guidelines
description: Python coding standards covering language, types, style, and patterns. Apply when writing, editing, or reviewing Python files, including pyproject.toml.
---

# Python Coding Guidelines

After finishing all edits, run `make lint` to format, fix, and type-check.
Do not worry about import ordering or formatting during edits. Ruff handles that.

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
- Simple and direct. No unnecessary abstractions, factories, or indirection.
- **Trust the stack; let it fail.** Validate only at external boundaries
  (CLI args, user input, untrusted data) with descriptive errors. Everywhere
  else, trust your own functions and library calls. No try/except wrappers
  that just log, print, or exit. Catch only when recovery is real (fallback
  value, retry, cleanup).

## Good Patterns

- **Error exit from scripts.** Prefer `raise SystemExit` over `print` plus `sys.exit`.

  ```python
  if not jsonl.is_file():
      raise SystemExit(f"error: no session transcript at {jsonl}")
  ```

- **Early return over nesting.**

  ```python
  def get_api_key(provided: str | None) -> str | None:
      if provided:
          return provided
      return os.environ.get("GEMINI_API_KEY")
  ```

- **Comments explain why, not what.**

  ```python
  # Claude Code replaces both / and spaces with - in project slugs
  project_slug = git_root.replace("/", "-").replace(" ", "-")
  ```

- **Trust the stack.** Let exceptions propagate. The traceback carries more
  signal than a manual print plus exit.

  Avoid:

  ```python
  try:
      response = client.generate(prompt)
  except Exception as e:
      print(f"Error: {e}", file=sys.stderr)
      sys.exit(1)
  ```

  Good:

  ```python
  response = client.generate(prompt)
  ```
