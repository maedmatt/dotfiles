"""Running mean and standard deviation of batched observations."""

from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING, Literal

import torch

if TYPE_CHECKING:
  from collections.abc import Iterable

_MIN_STD = 1e-6
"""A standard deviation at or below this value is replaced by 1.0, so that a
constant channel is shifted but not divided by a number near zero."""


@dataclass(kw_only=True)
class RunningNormalizerCfg:
  """Configuration for :class:`RunningNormalizer`."""

  dim: int
  """Width of one observation."""

  clip: float | None = 5.0
  """Normalized values are clamped to ``[-clip, clip]``. None disables clamping."""

  update_mode: Literal["cumulative", "exponential"] = "cumulative"
  """``cumulative`` gives every sample the same weight. ``exponential`` gives
  recent batches more weight, set by ``decay``."""

  decay: float = 0.99
  """Share of the old statistics kept at each update in ``exponential`` mode."""

  def __post_init__(self) -> None:
    if self.dim <= 0:
      raise ValueError(f"dim must be positive, got {self.dim}.")
    if self.clip is not None and self.clip <= 0.0:
      raise ValueError(f"clip must be positive or None, got {self.clip}.")
    if not 0.0 < self.decay < 1.0:
      raise ValueError(f"decay must be in (0, 1), got {self.decay}.")

  def build(self, device: str = "cpu") -> RunningNormalizer:
    return RunningNormalizer(self, device)


def fit_normalizer(
  cfg: RunningNormalizerCfg, batches: Iterable[torch.Tensor], device: str = "cpu"
) -> RunningNormalizer:
  """Build a normalizer and update it with every batch in ``batches``."""
  normalizer = cfg.build(device)
  for batch in batches:
    normalizer.update(batch.to(device))
  return normalizer


class RunningNormalizer:
  """Normalizes observations with the statistics of the data it has seen.

  Call :meth:`update` with each new batch, then :meth:`normalize`. Statistics are
  kept per channel: one mean and one standard deviation for each of the ``dim``
  columns.
  """

  def __init__(self, cfg: RunningNormalizerCfg, device: str = "cpu"):
    self.cfg = cfg
    self.device = device
    self._count = 0
    self._mean = torch.zeros(cfg.dim, device=device)
    self._var = torch.ones(cfg.dim, device=device)

  # Properties.

  @property
  def mean(self) -> torch.Tensor:
    """Per-channel mean. Shape (dim,)."""
    return self._mean

  @property
  def std(self) -> torch.Tensor:
    """Per-channel standard deviation. Shape (dim,)."""
    std = self._var.sqrt()
    return torch.where(std > _MIN_STD, std, torch.ones_like(std))

  # Methods.

  def update(self, obs: torch.Tensor) -> None:
    """Fold a batch of observations into the statistics.

    Args:
      obs: Observations of shape (..., dim). All leading dimensions count as
        samples.
    """
    batch = self._flatten(obs)
    if batch.shape[0] == 0:
      return
    weight = self._batch_weight(batch.shape[0])
    delta = batch.mean(dim=0) - self._mean
    # Variance of two merged groups: the weighted variances of each group, plus
    # the spread between the two group means.
    self._var = (
      (1.0 - weight) * self._var
      + weight * batch.var(dim=0, unbiased=False)
      + weight * (1.0 - weight) * delta**2
    )
    self._mean = self._mean + weight * delta
    self._count += batch.shape[0]

  def normalize(self, obs: torch.Tensor) -> torch.Tensor:
    """Return ``(obs - mean) / std`` with the shape of ``obs``."""
    if self._count == 0:
      raise RuntimeError("normalize() called before update().")
    normalized = (obs - self._mean) / self.std
    if self.cfg.clip is None:
      return normalized
    return normalized.clamp(-self.cfg.clip, self.cfg.clip)

  # Private methods.

  def _flatten(self, obs: torch.Tensor) -> torch.Tensor:
    if obs.shape[-1] != self.cfg.dim:
      raise ValueError(
        f"Expected observations of width {self.cfg.dim}, got shape {tuple(obs.shape)}."
      )
    return obs.reshape(-1, self.cfg.dim)

  def _batch_weight(self, batch_size: int) -> float:
    """Share of the updated statistics that comes from the new batch."""
    if self.cfg.update_mode == "exponential" and self._count > 0:
      return 1.0 - self.cfg.decay
    return batch_size / (self._count + batch_size)
