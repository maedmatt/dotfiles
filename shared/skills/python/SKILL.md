---
name: python
description: Write, refactor, and review Python so that it is typed, flat, and quick to read. Typed signatures, config dataclasses, small flat functions, one-line docstrings that state tensor shapes, and errors that name the bad value. Use for any task that writes or edits Python code, reviews Python code for style, or sets up a Python project.
---

# Python

Rules for Python code that is typed, flat, and quick to read. The examples come from robotics and reinforcement learning code; the rules apply to any Python project.

## Which rule applies

1. The project you are editing comes first. Its formatter, linter, and type checker settings, its indent width, and the names and patterns in neighbouring files override this skill. Read two or three files next to the one you change before you write.
2. This skill covers what the project does not decide.
3. In a project with no formatter or type checker, set up the tools in `references/project-setup.md` first.

More detail, loaded when needed:

- `references/tensors.md`: PyTorch and NumPy code, shapes, frames, devices.
- `references/project-setup.md`: uv, ruff, pyright, pytest, pre-commit, Makefile.
- `references/example.py` and `references/test_example.py`: one module and its tests that follow every rule here. Read them when you want to see the rules applied together.

## Check before you finish

Use the project's own commands if it has them (`make check`, `make test`). Otherwise:

```sh
uv run ruff format
uv run ruff check --fix
uv run pyright                        # or: uv run ty check
uv run pytest tests/test_<module>.py  # the tests of the module you changed
```

Code that fails the type checker is not finished. Report each command you could not run.

## Modules and imports

- Open the module with a one-line docstring that names what the module holds: `"""Reward manager for computing reward signals."""`. Add a paragraph only for a decision the reader needs, such as which module owns a behavior.
- Put `from __future__ import annotations` under the docstring of every module that has annotations.
- Import with absolute paths from the package root: `from mjlab.managers.reward_manager import RewardTermCfg`. ruff orders the blocks: standard library, third party, first party.
- An import used only in annotations goes under `if TYPE_CHECKING:`. The same block also prevents circular imports.
- Do not import inside a function. Two exceptions: a circular import that `TYPE_CHECKING` cannot solve, and an optional heavy dependency in a script (`import wandb` inside the branch that uploads).
- An `__init__.py` is empty, or holds a docstring and the re-exports of the public names, written `from pkg.module import Name as Name`. Do not write `__all__`.
- One concept per module, named after the thing it holds: `replay_buffer.py`, `reward_manager.py`. Aim for 150 to 200 lines. Past 500 lines, look for a second concept to move out.

## Names

- Spell names out: `default_joint_pos`, `motion_times`, `num_transitions`. Shorten only the words that robotics and machine learning code shortens everywhere: `pos`, `vel`, `quat`, `cfg`, `obs`, `dt`, `ids`, `idx`.
- Counts are `num_<things>`. Widths are `<thing>_dim`. Index collections are `<thing>_ids`.
- A class is a noun. The config of class `Foo` is `FooCfg`. An immutable description of a thing is `FooSpec`. An acronym in a class name is written as a word: `ManagerBasedRlEnv`, `IdealPdActuator`.
- A function starts with a verb that says what the caller gets: `build_mlp`, `create_env`, `load_runner_cfg`, `resolve_task_specs`, `compute_wm_obs`. Reward and observation terms are the exception, see `references/tensors.md`.
- A quantity with a unit carries the unit as a suffix: `episode_length_s`, `cooldown_s`. When there is no suffix, the docstring states the unit.
- A boolean reads as a statement: `is_fixed_base`, `has_delay`, `use_default_offset`, `enable_corruption`.
- A helper that other modules must not call starts with an underscore, in a module and in a class.
- Module constants are `UPPER_SNAKE`, private ones `_UPPER_SNAKE`, placed under the imports. A constant whose value is not obvious gets a comment or a docstring that says where the number comes from.
- One name per thing in the whole project. If the code already calls it `rep_state`, do not introduce `state_repr`.

## Types

- Annotate every parameter and every return value, including `-> None`.
- Write `X | None`, `list[int]`, `tuple[int, ...]`, `dict[str, torch.Tensor]`. Import `Callable`, `Sequence`, and `Iterable` from `collections.abc`. Do not use `Optional`, `List`, `Dict`, or `Union`.
- A string with a fixed set of values is a `Literal["uniform", "adaptive"]`, not a `str`.
- A fixed-length vector in a config is `tuple[float, float, float]`. Config defaults are tuples, not lists.
- Annotate a local variable when the type checker cannot infer it: `asset: Entity = env.scene[asset_cfg.name]`, `layers: list[nn.Module] = []`.
- A subclass that needs a narrower type for an inherited attribute declares it at class level: `cfg: MotionCommandCfg`.
- Narrow `X | None` with `assert x is not None` only when other code guarantees it, and name that code in a comment: `assert wandb.run is not None  # _init_wandb ran before the loop`. If a caller can cause the None, raise an error.
- Do not add `# type: ignore`. Fix the type, or use `cast` where a library returns a wider type than the code knows. If an ignore is unavoidable, give the error code: `# type: ignore[arg-type]`.

## Config dataclasses

Every tunable value lives in a dataclass named `<Thing>Cfg`. The class takes the config as `cfg` and reads `self.cfg.<field>`.

```python
@dataclass(kw_only=True)
class RunningNormalizerCfg:
  """Configuration for :class:`RunningNormalizer`."""

  dim: int
  """Width of one observation."""

  clip: float | None = 5.0
  """Normalized values are clamped to ``[-clip, clip]``. None disables clamping."""

  def __post_init__(self) -> None:
    if self.dim <= 0:
      raise ValueError(f"dim must be positive, got {self.dim}.")

  def build(self, device: str = "cpu") -> RunningNormalizer:
    return RunningNormalizer(self, device)
```

- Document a field with a string directly under it. State the unit and the meaning of special values ("0 disables"). tyro shows this string as the help text of the command-line flag.
- `kw_only=True` when the config has a field without a default or is subclassed.
- `frozen=True` for a value that nothing edits after creation.
- A nested config or any mutable default uses `field(default_factory=...)`.
- Validate in `__post_init__`, so a bad value fails where the config is created.
- A config that has one matching class builds it with a `build()` method.
- Make a variant with a function that calls the base function and edits the result, not with a chain of subclasses: `maxcoord_env_cfg()` calls `gencoord_env_cfg()` and replaces two observation groups.
- Callers edit the config they receive. So return a config from a function that builds a new object on each call, not from a module-level constant, and `deepcopy` a config that a class stores and later edits.
- A script parses its config dataclass with tyro in `main()`, and ends with `if __name__ == "__main__": main()`. `main()` only parses and then calls a function such as `run_train(task_id, cfg)`, which other code can import.

## Functions and classes

- Code without state is a module-level function. Write a class only when something must persist between calls.
- One function does one job and fits on one screen. Aim for about 10 lines and at most one nested block. Check preconditions first and return early, so the main path is not nested. For branch-heavy functions, use the `cyclomatic-complexity` skill.
- A config function or a script body may be long when it is a flat sequence of assignments and calls. Split it into blocks with one-sentence comments.
- Boolean flags and optional settings are keyword-only: `def __init__(self, cfg, env, *, scale_by_dt: bool = True)`. Call with keywords when a call passes several arguments of the same type.
- When construction takes several steps, write a `build_<thing>(cfg, ...)` function or a `from_<source>` classmethod, and keep `__init__` to assignments.
- A value derived from state without arguments is a `@property`. Do not write `get_x()` for it.
- Order a class body: class attributes, `__init__`, special methods, then three groups each introduced by a one-line comment: `# Properties.`, `# Methods.`, `# Private methods.`
- Define an abstract base class with `@abstractmethod` when two implementations exist. Keep inheritance shallow, and prefer passing a collaborator in over inheriting from it.
- Build a list or dict with a comprehension when each item is one expression. Use a loop when the body branches.

## Docstrings and comments

- The first line is one sentence that says what the function returns or does: `"""Reward for being alive."""`, `"""Build an MLP with LayerNorm and GELU between the linear layers."""`. Most docstrings are this single line.
- Add a body only for what the signature cannot say: the layout of a tensor, the unit, the coordinate frame, who calls the function, or why the function exists.
- Add `Args:` and `Returns:` sections (Google style) only when a parameter needs more than its name and type. Most functions do not need them.
- Put code names in double backticks, and link classes with `:class:` and methods with `:meth:`.
- A comment gives the reason or the invariant, never a restatement of the line: `# Past-the-end guard: searchsorted returns numel() at the final frame.`
- A comment is a sentence: capital letter, period, at most 88 columns.
- Write comments and docstrings in plain ASCII sentences, without arrows or em-dashes.
- Do not leave commented-out code or `TODO` notes. Finish the work or tell the user what is open.

## Errors and output

- `ValueError` for an argument or config value that is wrong. `RuntimeError` for a call in the wrong state or order (`"FootFrictionSpec.read() called before bind()"`). `NotImplementedError` in a method that subclasses must override. `TypeError` for a wrong type.
- The message states what was wrong with the actual value, what is allowed, and the fix when there is one:

```python
raise ValueError(
  f"Invalid input order: {self.cfg.input_order}. Must be 'pos_vel' or 'vel_pos'."
)
raise ValueError(
  "BuiltinPositionActuatorCfg does not support SITE transmission. "
  "Use BuiltinMotorActuatorCfg for site transmission."
)
```

- Check a value where it enters: `__post_init__`, a constructor, the first lines of a public function. Code further in trusts the value. Do not repeat checks deeper in, and do not wrap code in `try` unless you handle a specific exception.
- `assert` states an internal invariant, with a message. It is not for input a user can get wrong.
- A setting that is valid but probably a mistake gets `warnings.warn(message, UserWarning, stacklevel=2)`.
- Scripts report progress with `print(f"[INFO] ...")` and `print(f"[WARN] ...")`. Library code prints only a one-time notice during setup, never inside a function that runs every step. Use the `logging` module only where the project already does.

## Tests

- One file per module: `tests/test_<module>.py`. Shared fixtures and builders go in `tests/conftest.py`.
- Tests are functions with fixtures. Do not write test classes.
- The name states the behavior, and a one-line docstring states the expected result:

```python
def test_circular_buffer_overwrite(device):
  """Overwrites oldest once capacity reached."""
```

- One behavior per test. Build inputs with small helper functions at the top of the file (`_schema()`, `make_mock_env()`), and keep sizes small.
- Use `@pytest.mark.parametrize` for the same check over several values, and `pytest.raises(ValueError, match="...")` for error paths.
- Mark a test that takes seconds with `@pytest.mark.slow`.
- While you iterate, run the one test file you are working on, not the full suite.
