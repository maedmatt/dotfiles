---
description: Robotics and safety-critical overlay
---
Use this overlay for robotics, deployment, control, or any repo that can affect real
hardware.

Do not assume a file is sim-only just because it lives near training code. Verify
which path actually reaches hardware.

Safety rules:
- Never override the main run or deployment loop. Prefer additive changes that preserve
  existing safety mechanisms.
- Ask before modifying motor mappings, PD gains, action scaling, torque limits, or
  other actuator-facing parameters.
- Treat any config that maps to physical actuators or safety gates as safety-critical.
- Separate analysis from execution. If a real-world validation step is needed, call it
  out explicitly instead of silently bundling it into code changes.
