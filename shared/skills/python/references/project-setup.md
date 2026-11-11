# Project setup

The tool setup for a Python project. Use it when you start a Python project, or when an existing project has no formatter, linter, or type checker configured. If the project already configures a tool, keep its configuration.

## Layout

```
<project>/
  pyproject.toml
  uv.lock
  .python-version
  .pre-commit-config.yaml
  Makefile
  README.md
  src/<package>/      # all importable code
  tests/              # test_<module>.py files and conftest.py
```

- The package lives under `src/`, and tests live in a top-level `tests/` folder outside the package.
- Runnable entry points are modules in `src/<package>/scripts/`, each with a `main()` function. Register the ones users call often under `[project.scripts]`.
- uv manages the environment. Run everything through `uv run`, never through a bare `python` or `pip`.

## pyproject.toml

```toml
[build-system]
requires = ["uv_build>=0.12.1,<0.13.0"]
build-backend = "uv_build"

[project]
name = "<package>"
version = "0.1.0"
description = "<one sentence>"
readme = "README.md"
requires-python = ">=3.11"
dependencies = []

[dependency-groups]
dev = [
  "pre-commit",
  "pyright",
  "pytest",
  "ruff",
  "ty",
]

[tool.ruff]
src = ["src"]  # Lets the import sorter recognize first-party imports.
indent-width = 2

[tool.ruff.lint]
select = ["E4", "E7", "E9", "F", "I", "B"]
ignore = ["B011"]

[tool.pyright]
pythonVersion = "3.11"
venvPath = "."
venv = ".venv"
include = ["src"]

[tool.ty.src]
include = ["src", "tests"]

[tool.pytest.ini_options]
markers = [
  "slow: marks tests as slow (deselect with '-m \"not slow\"')",
]
addopts = "--strict-markers"
```

What each setting does:

- `indent-width = 2`: code is indented with two spaces. The line length stays at the ruff default of 88 columns, and that limit applies to code, comments, and docstrings.
- `select`: `E4`, `E7`, `E9` are the pycodestyle import, statement, and syntax errors; `F` is pyflakes (unused imports and names); `I` sorts imports; `B` is flake8-bugbear (likely bugs such as mutable default arguments).
- `ignore = ["B011"]`: allows `assert False`.
- `--strict-markers`: a misspelled pytest marker fails the run.
- Set `pythonVersion` and `requires-python` to the same minimum version. Use syntax newer than that version nowhere in the code.

## Pre-commit

`.pre-commit-config.yaml`:

```yaml
repos:
- repo: https://github.com/astral-sh/ruff-pre-commit
  rev: v0.14.14
  hooks:
    - id: ruff-check
      args: [ --fix ]
    - id: ruff-format
```

Install the hook once with `uv run pre-commit install`.

## Makefile

```make
.PHONY: format
format:
	uv run ruff format
	uv run ruff check --fix

.PHONY: type
type:
	uv run ty check
	uv run pyright

.PHONY: check
check: format type

.PHONY: test
test:
	uv run pytest

.PHONY: test-fast
test-fast:
	uv run pytest -m "not slow"

.PHONY: test-all
test-all: check test
```

`make check` runs before every commit. `make test-all` runs before every pull request.

## Continuous integration

Run three separate jobs on each push and pull request: ruff (`ruff check --diff` and `ruff format --diff`), pytest, and pyright. A pull request that fails type checking is not merged.

## Lines for the project rule file

Put the commands above into the project's `AGENTS.md` or `CLAUDE.md`, so that every agent runs them. State these four rules there as well:

- Always use `uv run`, not `python`.
- Run `make check` before committing. Do not commit code that fails type checking.
- The line length limit is 88 columns for code, comments, and docstrings.
- Avoid imports inside functions unless they are strictly necessary, for example to break a circular import.
