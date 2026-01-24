# Codebase Primer Template

Use this structure when generating `CODEBASE_PRIMER.md`:

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
