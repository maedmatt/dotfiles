#!/usr/bin/env -S uv run --script
"""Extract conversation text from a Claude Code session JSONL transcript.

Strips images, tool results, progress messages, file snapshots, and
system reminders. Outputs only user messages and Claude's text responses.
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

SYSTEM_REMINDER_RE = re.compile(r"<system-reminder>.*?</system-reminder>", re.DOTALL)


def find_session_jsonl(session_id: str | None = None) -> Path:
    project_dir = Path.home() / ".claude" / "projects"

    # Derive project slug from git root
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise SystemExit("error: not in a git repository")

    git_root = result.stdout.strip()
    project_slug = git_root.replace("/", "-")
    session_dir = project_dir / project_slug

    if not session_dir.is_dir():
        raise SystemExit(f"error: no session directory at {session_dir}")

    if session_id:
        jsonl = session_dir / f"{session_id}.jsonl"
    else:
        # Most recently modified JSONL
        jsonls = sorted(
            session_dir.glob("*.jsonl"), key=lambda p: p.stat().st_mtime, reverse=True
        )
        jsonl = jsonls[0] if jsonls else None

    if not jsonl or not jsonl.is_file():
        raise SystemExit("error: no session transcript found")

    return jsonl


def clean_text(text: str) -> str:
    """Remove system reminder tags from text."""
    return SYSTEM_REMINDER_RE.sub("", text).strip()


def extract(jsonl_path: Path) -> str:
    lines = []

    for raw_line in jsonl_path.read_text().splitlines():
        d = json.loads(raw_line)
        msg_type = d.get("type")

        if msg_type == "user":
            content = d.get("message", {}).get("content", "")
            texts = []
            if isinstance(content, str):
                texts.append(content)
            elif isinstance(content, list):
                for block in content:
                    if block.get("type") == "text":
                        texts.append(block["text"])

            for text in texts:
                cleaned = clean_text(text)
                if not cleaned:
                    continue
                lines.append(f"USER: {cleaned}")
                lines.append("")

        elif msg_type == "assistant":
            content = d.get("message", {}).get("content", [])
            if isinstance(content, list):
                for block in content:
                    if block.get("type") == "text":
                        cleaned = clean_text(block["text"])
                        if cleaned:
                            lines.append(f"CLAUDE: {cleaned}")
                            lines.append("")

    return "\n".join(lines)


if __name__ == "__main__":
    session_id = sys.argv[1] if len(sys.argv) > 1 else None
    jsonl_path = find_session_jsonl(session_id)
    print(extract(jsonl_path))
