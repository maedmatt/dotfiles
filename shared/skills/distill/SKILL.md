---
name: distill
description: Analyze and distill ML/RL research codebases into actionable primers. Use when exploring a cloned repository to understand its implementation, extract novel patterns, and prepare context for future development. Produces a CODEBASE_PRIMER.md documenting architecture, algorithms, key code snippets, and adaptation guidance. Optimized for robotics and reinforcement learning papers.
context: fork
agent: Explore
allowed-tools: Read, Grep, Glob
---

# Distill

Analyze an ML/RL research codebase and produce a distilled primer for learning and future reference.

## Workflow

1. Check for optional `PAPER_CONTEXT.md` (abstract, key contributions, relevant equations)
2. Explore the codebase structure thoroughly
3. Extract and analyze relevant components
4. Generate `CODEBASE_PRIMER.md` in the repo root

## What to Extract

Focus exclusively on the research contribution. Identify and document:

- Model architecture definitions (networks, modules, custom layers)
- Loss functions and objectives
- Reward shaping and reward engineering
- Training loop logic and update rules
- Key hyperparameters (especially those mentioned in paper or that deviate from defaults)
- Novel data augmentation or preprocessing
- Observation and action space design
- Environment wrappers and modifications

## What to Ignore

Skip implementation details unrelated to the core contribution:

- Logging and experiment tracking (wandb, tensorboard callbacks)
- Config/CLI parsing (hydra, argparse, omegaconf boilerplate)
- Checkpoint saving/loading mechanics
- Distributed training setup
- Standard dataset loading unless novel

Note these exist only if needed to run the code.

## Distinguishing Novel vs Standard

Explicitly identify what comes from external libraries versus what the paper contributes:

```
They use SAC from stable-baselines3 but modify the critic network:
[code snippet of modification]
```

Common RL frameworks to recognize: stable-baselines3, CleanRL, rllab, Tianshou, RLlib, SKRL.
Common simulators: MuJoCo, Isaac Gym, Isaac Lab, PyBullet, Gymnasium, robosuite, dm_control.

## Code Snippet Format

Include actual code for novel/interesting components. Annotate with location and explanation:

### [Component Name]

[One sentence: what this does and why it matters]

```python
# from path/to/file.py:XX-YY
[relevant code, trimmed to essential lines]
```

[Explanation of the approach and design choices]

**Adaptation notes**: [What to consider when applying this to a different task/robot]

Keep snippets focused. Extract only the lines that matter, not entire classes.

## Output Structure

Generate `CODEBASE_PRIMER.md` following the template in `references/primer-template.md`.

## Paper Context (Optional)

If `PAPER_CONTEXT.md` exists in repo root, use it to:

- Map code sections to paper sections where possible
- Verify hyperparameters match paper claims
- Anchor explanations to paper terminology

If absent, proceed without. The primer should stand alone.

## Final Output

Save primer to `CODEBASE_PRIMER.md` in the repo root. This file is designed to be used as context in a fresh conversation for applying the learned patterns.
