---
description: Remove AI code slop
---

Review the changes introduced in this revision and remove any AI-generated slop.

This includes:
- Comments inconsistent with the file's style or clearly unnecessary
- Defensive checks, try/catch blocks, or control flow that don't fit the conventions of the surrounding code (especially in trusted paths)
- Casts to any that are only used to bypass type issues
- Variables used exactly once immediately after declaration; inline the expression instead
- Any other patterns that deviate from the file's established style

Report at the end with a concise 1–3 sentence summary of what you changed.
