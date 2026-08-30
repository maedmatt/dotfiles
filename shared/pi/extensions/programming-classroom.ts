import { existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import {
  CustomEditor,
  type ExtensionAPI,
  type ExtensionCommandContext,
  type ExtensionContext,
} from "@earendil-works/pi-coding-agent";

/**
 * Load Kai's canonical programming tutor skill only when Matteo wants a lesson.
 *
 * Interactive: /teach on | /teach off | /teach status
 * New session: pi --teach
 * Override the canonical skill path with PI_PROGRAMMING_CLASSROOM_SKILL.
 */
const STATE_TYPE = "programming-classroom-mode";
const SKILL_NAME = "programming-classroom-tutor";
const MODE_LABEL = " teaching: on ";
const DEFAULT_SKILL_PATH = join(
  homedir(),
  ".openclaw",
  "workspace",
  "skills",
  SKILL_NAME,
  "SKILL.md",
);

interface TeachingModeState {
  enabled: boolean;
}

function skillPath(): string {
  return process.env.PI_PROGRAMMING_CLASSROOM_SKILL?.trim() || DEFAULT_SKILL_PATH;
}

function savedMode(ctx: ExtensionContext): boolean | undefined {
  let restored: boolean | undefined;

  for (const entry of ctx.sessionManager.getBranch()) {
    if (entry.type !== "custom" || entry.customType !== STATE_TYPE) continue;
    const data = entry.data as Partial<TeachingModeState> | undefined;
    if (typeof data?.enabled === "boolean") restored = data.enabled;
  }

  return restored;
}

function requestedMode(args: string, current: boolean): boolean | "status" | undefined {
  const value = args.trim().toLowerCase();
  if (!value) return !current;
  if (value === "on" || value === "enable" || value === "enabled") return true;
  if (value === "off" || value === "disable" || value === "disabled") return false;
  if (value === "status") return "status";
  return undefined;
}

function installTeachingEditor(ctx: ExtensionContext): void {
  if (!ctx.hasUI) return;

  // Preserve an editor installed by another extension, such as the Ghostty
  // Shift+Enter adapter, and add only the classroom presentation around it.
  const baseFactory = ctx.ui.getEditorComponent();
  const uiTheme = ctx.ui.theme;

  ctx.ui.setEditorComponent((tui, theme, keybindings) => {
    const editor = baseFactory?.(tui, theme, keybindings) ?? new CustomEditor(tui, theme, keybindings);
    const teachingBorder = (text: string) => {
      if (editor.getText().trimStart().startsWith("!")) {
        return uiTheme.getBashModeBorderColor()(text);
      }
      return uiTheme.fg("warning", text);
    };

    // Pi normally updates the border when thinking/model state changes. Teaching
    // mode keeps its own color, while retaining the standard bash-mode color.
    Object.defineProperty(editor, "borderColor", {
      get: () => teachingBorder,
      set: () => {},
      configurable: true,
      enumerable: true,
    });

    const renderBase = editor.render.bind(editor);
    editor.render = (width: number) => {
      const lines = renderBase(width);
      if (lines.length < 2) return lines;

      const topPlain = (lines[0] ?? "").replace(/\x1b\[[0-?]*[ -/]*[@-~]/g, "");
      const scrollPrefix = topPlain.match(/^(─── ↑ \d+ more )/)?.[1];
      const prefix = scrollPrefix ?? "──";
      const remaining = width - prefix.length - MODE_LABEL.length;
      if (remaining < 1) return lines;

      lines[0] =
        teachingBorder(prefix) +
        uiTheme.bold(uiTheme.fg("warning", MODE_LABEL)) +
        teachingBorder("─".repeat(remaining));
      return lines;
    };

    return editor;
  });
}

async function changeMode(
  pi: ExtensionAPI,
  args: string,
  ctx: ExtensionCommandContext,
  current: boolean,
  setCurrent: (enabled: boolean) => void,
): Promise<void> {
  const requested = requestedMode(args, current);
  if (requested === undefined) {
    ctx.ui.notify("Usage: /teach [on|off|status]", "warning");
    return;
  }

  if (requested === "status") {
    ctx.ui.notify(`Programming teaching mode is ${current ? "enabled" : "disabled"}.`, "info");
    return;
  }

  if (requested && !existsSync(skillPath())) {
    ctx.ui.notify(`Tutor skill not found: ${skillPath()}`, "error");
    return;
  }

  if (requested === current) {
    ctx.ui.notify(`Programming teaching mode is already ${current ? "enabled" : "disabled"}.`, "info");
    return;
  }

  setCurrent(requested);
  pi.appendEntry(STATE_TYPE, { enabled: requested } satisfies TeachingModeState);
  ctx.ui.notify(
    requested
      ? "Programming teaching mode enabled. Reloading the tutor skill."
      : "Programming teaching mode disabled. Reloading Pi.",
    "info",
  );
  await ctx.reload();
}

export default function programmingClassroom(pi: ExtensionAPI) {
  let enabled = false;

  pi.registerFlag("teach", {
    description: "Start with programming teaching mode enabled",
    type: "boolean",
    default: false,
  });

  pi.on("session_start", (_event, ctx) => {
    enabled = savedMode(ctx) ?? Boolean(pi.getFlag("teach"));
    if (enabled && !existsSync(skillPath())) {
      enabled = false;
      ctx.ui.notify(`Programming teaching mode could not find ${skillPath()}`, "error");
    }
    if (enabled) installTeachingEditor(ctx);
  });

  pi.on("resources_discover", () => {
    if (!enabled) return undefined;
    return { skillPaths: [skillPath()] };
  });

  pi.on("before_agent_start", (event) => {
    if (!enabled) return undefined;

    const loaded = event.systemPromptOptions.skills?.some((skill) => skill.name === SKILL_NAME) ?? false;
    const skillInstruction = loaded
      ? `Teaching mode is active. The ${SKILL_NAME} skill is mandatory for this session. Read it before the first teaching action and keep following it on every turn. Its teaching rules take precedence over ordinary coding-assistant defaults.`
      : `Teaching mode is active, but the ${SKILL_NAME} skill did not load. Stop and tell Matteo the tutor skill is unavailable at ${skillPath()}.`;

    return { systemPrompt: `${event.systemPrompt}\n\n## Programming teaching mode\n\n${skillInstruction}` };
  });

  pi.registerCommand("teach", {
    description: "Toggle programming teaching mode, or use /teach on|off|status",
    handler: async (args, ctx) => {
      await changeMode(pi, args, ctx, enabled, (next) => {
        enabled = next;
      });
    },
  });
}
