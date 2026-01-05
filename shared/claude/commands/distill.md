---
name: distill
description: Analyze and distill ML/RL research codebases into actionable primers. Use when exploring a cloned repository to understand its implementation, extract novel patterns, and prepare context for future development. Produces a CODEBASE_PRIMER.md documenting architecture, algorithms, key code snippets, and adaptation guidance. Optimized for robotics and reinforcement learning papers.
---

# Distill

Analyze an ML/RL research codebase and produce a distilled primer for learning and future reference.

## Workflow

1. User has already cloned the repo and is in its root directory
2. Check for optional `PAPER_CONTEXT.md` (abstract, key contributions, relevant equations)
3. Explore the codebase structure
4. Extract and analyze relevant components
5. Generate `CODEBASE_PRIMER.md` in the repo root

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

Explicitly identify what comes from external libraries versus what the paper contributes. Use this pattern:

```
They use SAC from stable-baselines3 but modify the critic network:
[code snippet of modification]
```

Common RL frameworks to recognize: stable-baselines3, CleanRL, rllab, Tianshou, RLlib, SKRL. Common simulators: MuJoCo, Isaac Gym, Isaac Lab, PyBullet, Gymnasium, robosuite, dm_control.

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

Generate `CODEBASE_PRIMER.md` with this structure:

```markdown
# Codebase Primer: [repo-name]

## Overview
What this implements, the core approach, paper reference if known.

## Environment & Task
Simulator used, observation space, action space.
What's standard vs custom environment code.
Note portability: how coupled is the algo to this specific env?

## Core Algorithm
The main contribution with annotated code snippets.
Clearly mark: "Novel to this paper" vs "Standard [library] usage"

## Key Hyperparameters
Only the ones that matter. Include:
- Parameter name and value
- Where it's set (file:line or config key)
- Rationale if known from paper or comments

## Adaptation Guide
What's generalizable vs task-specific.
Concrete guidance: "To use this with a different robot, you would need to..."
Note difficulty: what's easy to swap out, what requires deeper changes.

## File Map
Quick reference to key files:
- `path/to/model.py` - Network architectures
- `path/to/train.py` - Training loop
- etc.
```

## Paper Context (Optional)

If `PAPER_CONTEXT.md` exists in repo root, use it to:

- Map code sections to paper sections where possible
- Verify hyperparameters match paper claims
- Anchor explanations to paper terminology

If absent, proceed without. The primer should stand alone.

## Final Output

Save primer to `CODEBASE_PRIMER.md` in the repo root. This file is designed to be used as context in a fresh conversation for applying the learned patterns.
