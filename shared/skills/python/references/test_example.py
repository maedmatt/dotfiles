"""Tests for the running normalizer in example.py."""

import pytest
import torch
from example import RunningNormalizer, RunningNormalizerCfg, fit_normalizer


@pytest.fixture
def normalizer() -> RunningNormalizer:
  """Cumulative normalizer over three channels, without clamping."""
  return RunningNormalizerCfg(dim=3, clip=None).build()


def _two_batches() -> tuple[torch.Tensor, torch.Tensor]:
  """Two batches of different size, mean, and spread. Shapes (64, 3), (32, 3)."""
  torch.manual_seed(0)
  return torch.randn(64, 3), torch.randn(32, 3) * 2.0 + 1.0


def test_update_matches_statistics_of_all_batches(normalizer):
  """Two updates give the mean and std of the concatenated data."""
  first, second = _two_batches()
  normalizer.update(first)
  normalizer.update(second)
  data = torch.cat([first, second], dim=0)
  assert torch.allclose(normalizer.mean, data.mean(dim=0), atol=1e-5)
  assert torch.allclose(normalizer.std, data.std(dim=0, unbiased=False), atol=1e-5)


def test_update_flattens_leading_dimensions(normalizer):
  """A (num_envs, num_steps, dim) batch counts every step as one sample."""
  first, _ = _two_batches()
  normalizer.update(first.reshape(8, 8, 3))
  assert torch.allclose(normalizer.mean, first.mean(dim=0), atol=1e-5)


def test_constant_channel_is_shifted_not_scaled(normalizer):
  """A channel with zero variance maps to zero instead of dividing by zero."""
  obs = torch.tensor([[2.0, 0.0, 1.0], [2.0, 1.0, 3.0]])
  normalizer.update(obs)
  assert torch.equal(normalizer.normalize(obs)[:, 0], torch.zeros(2))


def test_normalize_clamps_to_clip():
  """Values further than ``clip`` standard deviations from the mean are clamped."""
  normalizer = RunningNormalizerCfg(dim=1, clip=2.0).build()
  normalizer.update(torch.tensor([[-1.0], [1.0]]))
  assert normalizer.normalize(torch.tensor([[100.0]])).item() == 2.0


def test_exponential_mode_weights_new_batch_by_one_minus_decay():
  """After the first batch, a new batch moves the mean by ``1 - decay``."""
  cfg = RunningNormalizerCfg(dim=1, update_mode="exponential", decay=0.9)
  normalizer = fit_normalizer(cfg, [torch.zeros(4, 1), torch.ones(4, 1)])
  assert normalizer.mean.item() == pytest.approx(0.1)


def test_normalize_before_update_raises(normalizer):
  """normalize() needs at least one update()."""
  with pytest.raises(RuntimeError, match="before update"):
    normalizer.normalize(torch.zeros(1, 3))


def test_update_rejects_wrong_width(normalizer):
  """The last dimension of a batch must equal ``cfg.dim``."""
  with pytest.raises(ValueError, match="width 3"):
    normalizer.update(torch.zeros(4, 5))


@pytest.mark.parametrize("decay", [0.0, 1.0, -0.5])
def test_cfg_rejects_decay_outside_open_interval(decay):
  """decay must lie strictly between 0 and 1."""
  with pytest.raises(ValueError, match="decay"):
    RunningNormalizerCfg(dim=3, decay=decay)
