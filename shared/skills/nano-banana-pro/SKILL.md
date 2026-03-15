# Nano Banana Pro Image Generation & Editing Tool

This is a skill for generating and editing images using Google's Nano Banana Pro API (Gemini 3 Pro Image).

## Key Capabilities

- **Text-to-image generation**: Create new images from text descriptions
- **Image-to-image editing**: Modify existing images with text instructions
- **Resolution options**: 1K (~1024px), 2K (~2048px), 4K (~4096px)

## Basic Usage

The tool is run via `uv` from the user's current working directory:

**Generate:**
```bash
uv run ~/.claude/skills/nano-banana-pro/scripts/generate_image.py --prompt "description" --filename "output.png"
```

**Edit:**
```bash
uv run ~/.claude/skills/nano-banana-pro/scripts/generate_image.py --prompt "editing instructions" --filename "output.png" --input-image "input.png"
```

## Recommended Workflow

1. Start with 1K resolution for quick feedback
2. Iterate on the prompt with new filenames per run
3. Only render at 4K once the prompt is finalized

## Filename Convention

Files should follow the pattern: `yyyy-mm-dd-hh-mm-ss-descriptive-name.png`

## API Key Requirements

The script needs a Gemini API key via either the `--api-key` argument or `GEMINI_API_KEY` environment variable. If you get an API key error, ask the user to add `GEMINI_API_KEY` to their `~/.claude/settings.json` under `"env"`.

## Prompt Guidance

For generation, user descriptions are passed through largely as-is. For editing, instructions should be specific about what to change while the tool attempts to preserve other aspects of the original image.
