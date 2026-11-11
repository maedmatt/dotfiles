# Tensor code

Conventions for PyTorch and NumPy code, and for simulation code that steps many environments in one batch. Read this file when the code you write creates, indexes, or documents tensors.
## Names carry the quantity and the frame

A tensor name has three parts: the object, the physical quantity, and the coordinate frame.

```python
root_link_pos_w      # Position of the root link, world frame.
body_link_quat_w     # Orientation of every body link, world frame.
root_link_lin_vel_b  # Linear velocity of the root link, body frame.
projected_gravity_b  # Gravity direction, body frame.
```

- Quantities: `pos` (3), `quat` (4), `lin_vel` (3), `ang_vel` (3), `pose` (position and quaternion, 7), `vel` (linear and angular velocity, 6).
- Frame suffix: `_w` for the world frame, `_b` for the body frame. A quantity with no frame, such as `joint_pos`, gets no suffix.
- Counts are `num_<things>` (`num_envs`, `num_joints`). Widths of a flat vector are `<thing>_dim` (`rep_state_dim`). Index tensors are `<thing>_ids` (`env_ids`, `joint_ids`).
- State the quaternion order once per project, in a docstring, for example `(w, x, y, z)`.
- A width that the code slices by gets a name: `POS_DIM = 3`, `ROOT_STATE_DIM = ROOT_POSE_DIM + ROOT_VEL_DIM`.

## State the shape where the tensor is defined

A reader cannot see a shape in the code, so the docstring gives it. One sentence for the meaning, then the shape with named dimensions:

```python
@property
def root_link_pos_w(self) -> torch.Tensor:
  """Root link position in world frame. Shape (num_envs, 3)."""
```

- Use the names of the dimensions, not numbers that happen to be true today: `(num_envs, num_bodies, 7)`.
- `...` stands for any leading batch dimensions: `rot_mat: (..., 3, 3) rotation matrix`.
- When a flat vector packs several quantities, write the layout with the width of each part:

```python
"""Full state: [root_pos(3), root_quat(4), joint_pos(N), root_lin_vel(3), root_ang_vel(3), joint_vel(N)]"""
```

- Inside a function, a trailing comment gives the shape after a step that changes it: `ages = current_age[:, None] + offsets  # (B, L), newest last`.
- Dense index arithmetic may use one capital letter per dimension, if one line at the top of the function binds each letter to its full name: `L, B, E, T = sequence_length, batch_size, self.num_envs, self.buffer_size`.

## Operations

- Name the dimension in every reduction and concatenation: `torch.sum(x, dim=1)`, `torch.cat([a, b], dim=-1)`.
- Write functions that accept any leading batch dimensions. Index from the end with an ellipsis (`full_state[..., :7]`) and reduce over `dim=-1`.
- Add a broadcast dimension with `[:, None]`, and say so in a shape comment when the result is not obvious.
- Replace a Python loop over environments or bodies with one batched operation. A loop over time steps or over a short list of named terms is fine.
- `zip(a, b, strict=True)` when the two sequences must have the same length. A length mismatch then raises instead of dropping the extra items.
- Two index tensors used together (`x[env_ids, joint_ids]`) pair their entries one to one. To select every joint for every environment, index with `env_ids[:, None]`.

## Device and dtype

- A class that owns tensors takes `device` in its constructor, stores it, and passes `device=self.device` to every tensor it creates. Do not call `.cuda()`.
- A stateless function creates new tensors on the device of an input: `torch.arange(n, device=x.device)`, `x.new_zeros(...)`, `torch.zeros_like(x)`.
- State the dtype when it is not the default float: `torch.zeros(num_envs, dtype=torch.bool, device=device)`.

## Buffers and resets

- Allocate per-environment buffers once in `__init__`, then write into them in place: `self._reward_buf[:] = 0.0`, `self._episode_sums[name][env_ids] = 0.0`.
- A method that resets a subset of environments takes `env_ids: torch.Tensor | slice | None = None`, and turns None into "all environments" on its first lines:

```python
def reset(self, env_ids: torch.Tensor | slice | None = None) -> None:
  if env_ids is None:
    env_ids = slice(None)
  self._episode_sums[env_ids] = 0.0
```

- `.clone()` a tensor read from the simulation or from stored defaults before you change it. Without the clone, the write changes the source.
- In an `nn.Module`, register a tensor that is not a parameter with `register_buffer`, so that `.to(device)` moves it and `state_dict()` saves it.

## Numerical guards

A clamp, an epsilon, or a threshold gets a comment that says what breaks without it:

```python
# The clamp keeps cos_angle away from the acos singularity at 1 and -1, so the
# gradient stays finite for identical inputs.
cos_angle = torch.clamp((trace - 1.0) / 2.0, -1.0 + 1e-7, 1.0 - 1e-7)
```

A threshold used in more than one place becomes a named module constant with that explanation as its docstring.

## Term functions

Rewards, observations, and terminations are plain functions. Each takes the environment first, then keyword parameters with defaults, and returns one tensor with one row per environment:

```python
def joint_vel_l2(
  env: ManagerBasedRlEnv, asset_cfg: SceneEntityCfg = _DEFAULT_ASSET_CFG
) -> torch.Tensor:
  """Penalize joint velocities on the articulation using L2 squared kernel."""
  asset: Entity = env.scene[asset_cfg.name]
  return torch.sum(torch.square(asset.data.joint_vel[:, asset_cfg.joint_ids]), dim=1)
```

A term is named for the quantity it returns, not with a verb: `joint_vel_l2`, `base_lin_vel`, `is_alive`. An event, which changes the simulation and returns nothing, is named with a verb: `reset_root_state_uniform`.

A term becomes a class with `__init__(self, cfg, env)` and `__call__` only when it must resolve something once (names into indices) or keep state between steps.

## Tests

- Seed first: `torch.manual_seed(0)`.
- Use the smallest sizes that show the behavior (4 environments, 3 channels).
- Compare floats with `torch.allclose(actual, expected, atol=1e-5)`, and exact values with `torch.equal`.
- Take the device from a `device` fixture, so that the same test runs on the CPU and on a GPU.
