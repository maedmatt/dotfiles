---
name: codex-image-gen
description: Generate or edit image artifacts by delegating to Codex CLI's built-in image generation tool; do not use for standalone image analysis, PNG reading, or visual QA.
---

# Codex Image Generation

Use this skill only when the user wants a new or modified image artifact produced through Codex CLI's built-in image generation capability. For standalone analysis, description, or reading of existing PNG/JPEG/image files where no new image artifact is requested, use the current multimodal model or image-reading tools directly instead of invoking Codex.

## Required behavior

1. Route image creation through `codex`/`codex exec`; do not call a local image generation tool or the OpenAI Images API directly for this workflow.
2. Explicitly invoke Codex image generation in the delegated prompt with `$imagegen` unless the user specifically wants an exploratory Codex session.
3. Treat Codex CLI authentication and usage limits as the execution boundary. Do not ask the user to paste credentials in chat; if authentication is missing, tell them to run `codex login` locally.
4. Keep the delegated Codex task narrow: generate or edit the requested image and report the actual generated output path. Prefer generation-only delegation; the outer agent should verify and place/copy the final artifact into the requested workspace path.
5. Verify that the expected image file exists and inspect the generated result before claiming success.
6. Do not delegate standalone image-only analysis, PNG reading, screenshot interpretation, OCR, or visual QA to Codex. When the task is image editing or reference-based generation, attach the source/reference images to Codex so it can analyze them as part of producing the new image artifact.

## When to use

- New image assets: icons, logos, banners, illustrations, product mockups, thumbnails, sprites, placeholders, diagrams, or concept art.
- Image edits: change a background, remove or replace an object, preserve a subject while changing style, apply a reference style, or localize text.
- Codex-mediated generation where the current harness should indirectly call Codex CLI rather than using its own image tool.

## Non-goals

- Do not use this skill to analyze, summarize, compare, caption, OCR, or read existing images unless that analysis is required to generate an edited/new image artifact.
- Do not call Codex just to inspect PNG/JPEG files, screenshots, diagrams, or generated outputs.
- Do not route post-generation visual QA to Codex; inspect generated artifacts with the current multimodal model/tooling after Codex creates them.

## Preconditions

Before a live run, check the local Codex CLI once when the environment is unknown:

```bash
codex --version
codex features list
```

`image_generation` should be available. If it is disabled in a specific environment, run the image task with `--enable image_generation` or ask the user to enable it with:

```bash
codex features enable image_generation
```

## Delegation command pattern

Prefer non-interactive execution so the outer agent can verify artifacts deterministically. Current Codex CLI versions do **not** support `--ask-for-approval`; use a config override for non-interactive approval policy:

```bash
codex exec \
  --ephemeral \
  --skip-git-repo-check \
  --sandbox read-only \
  -c 'approval_policy="never"' \
  --enable image_generation \
  --cd <workspace> \
  --output-last-message <tmp-dir>/codex-image-gen-last-message.md \
  "<delegated prompt>"
```

Use `--json` only when you need Codex transcript events for debugging. For image editing or reference-based generation, pass every source/reference image to Codex with `-i` / `--image` and describe each image's role in the delegated prompt:

```bash
codex exec \
  --ephemeral \
  --skip-git-repo-check \
  --sandbox read-only \
  -c 'approval_policy="never"' \
  --enable image_generation \
  --cd <workspace> \
  --image source.png \
  --image style-reference.png \
  --output-last-message <tmp-dir>/codex-image-gen-last-message.md \
  "<delegated edit prompt>"
```

Use `--sandbox read-only` for the nested Codex run whenever the outer agent can copy/place the artifact afterward. This avoids depending on nested shell filesystem commands. Use `--sandbox workspace-write` only when the nested Codex agent genuinely must edit files, and keep that scope explicit.

## Image-edit generation workflow

Use this skill for edits because edits produce a new image artifact. In that case, Codex must receive the relevant image inputs, not just a textual summary.

1. Attach the original/source image and any reference images with `--image`.
2. In the delegated prompt, label each image by path and role, for example: `source.png = image to edit`, `style-reference.png = style reference`.
3. State what Codex should analyze from each image: subject identity, layout, colors, text, lighting, style, or object boundaries.
4. State edit invariants explicitly: what must remain unchanged and what may change.
5. Ask Codex to generate the edited output artifact and report the actual generated path. The outer agent is responsible for copying/placing the final file after verification.

## Delegated prompt template

Include a concise, self-contained prompt for the nested Codex run:

```text
Use $imagegen to generate/edit an image.

Task: <generate or edit request>
Requested final path for outer agent: <workspace-relative final path>
Reference images: <paths and roles, if any>
Exact text to render: "<verbatim text>", if any
Style: <medium, mood, camera/composition, palette>
Constraints: <must keep, must avoid, transparent background, aspect ratio, size>

Do not run shell commands, copy files, or modify unrelated files. Use `$imagegen` only. If the image tool can write directly to the requested final path, do so and report that path. Otherwise report the exact generated image file path or generated image directory; the outer agent will inspect and copy it.
```

## Output and path rules

- Treat the requested output path as the final destination owned by the outer agent, not as a guarantee that nested Codex can write there.
- The built-in image tool often writes under Codex's generated image area, for example `~/.codex/generated_images/<session-id>/`. If Codex reports only a directory, inspect that directory and choose the generated image file explicitly.
- Because the built-in image tool may not guarantee an exact filename parameter, always verify the actual generated file path after Codex returns.
- Copy or move the generated image to the requested final path only after inspecting that it is the intended image.
- Do not claim that an image was created unless both the generated artifact and the requested final artifact exist, or unless you explicitly report that placement failed after generation.

## Prompting rules

- State the asset purpose and the requested format in the prompt.
- For text in images, quote the exact text and say it must be sharp, legible, correctly spelled, and placed where requested.
- For edits, list invariants explicitly: what must stay unchanged, what may change, and what must be avoided.
- For multi-image edits, label each input by index/path and role.
- For transparent or production assets, explicitly request transparent background, clean edges, no watermark, and the desired aspect ratio.
- For batches, generate only the requested number of images. If the user did not specify a count and the batch would be large, ask before spending Codex usage.

## Verification

After `codex exec` returns:

1. Read the captured last-message file or JSON events to identify Codex's reported output path or output directory.
2. Check the requested output path, any path reported by Codex, and Codex's generated image area when a session id is available.
3. Inspect the generated image with the current multimodal model/tooling for the user's constraints: subject, style, composition, text spelling, transparency/background, and edit invariants.
4. If the image was generated outside the requested path, copy or move the inspected file to the requested path with the outer agent's filesystem tools, then verify the requested path exists.
5. If the result is wrong and the user asked for a finished asset, rerun with one targeted correction. Do not hide failed generations.

## Failure handling

- `codex` command missing: report that Codex CLI is not installed or not on `PATH`.
- Authentication missing: tell the user to run `codex login`; do not request secrets in chat.
- Feature unavailable: report the missing `image_generation` feature and the enable command.
- CLI option drift: if `codex exec` rejects an option, run `codex exec --help` and update the invocation. In particular, replace obsolete `--ask-for-approval never` with `-c 'approval_policy="never"'` on current CLI versions.
- Nested shell sandbox failure after generation, such as `bwrap: loopback: Failed RTM_NEWADDR: Operation not permitted`, is usually a file-placement failure, not necessarily an image-generation failure. Inspect Codex's reported generated image directory and copy the verified image with the outer agent instead of rerunning blindly.
- No output path found: inspect the Codex last message/transcript and output directory; if still absent, report that Codex did not return an image artifact.
- Safety or policy refusal from Codex: report the refusal accurately and offer a compliant alternative prompt.

## Guardrails

- Do not use this skill as a generic image API wrapper; its purpose is Codex CLI delegation for image generation/edit-generation.
- Do not use this skill for standalone image understanding. Existing image analysis belongs to the current multimodal model/tooling unless Codex needs the image as input to produce an edited/generated artifact.
- Do not fabricate output filenames, dimensions, or successful generation.
- Do not overwrite existing assets without checking whether the path already exists or the user explicitly requested replacement.
- Do not leave temporary prompts, transcripts, or failed intermediate images in final asset directories.
