import { CustomEditor, type ExtensionAPI, type KeybindingsManager } from "@earendil-works/pi-coding-agent";
import { matchesKey, type EditorTheme, type TUI } from "@earendil-works/pi-tui";

class GhosttyShiftEnterEditor extends CustomEditor {
	constructor(tui: TUI, theme: EditorTheme, keybindings: KeybindingsManager) {
		super(tui, theme, keybindings);
	}

	handleInput(data: string): void {
		// Ghostty reports Shift+Enter as Alt+Enter in Pi's Kitty keyboard mode.
		if (matchesKey(data, "alt+enter")) {
			super.handleInput("\n");
			return;
		}
		super.handleInput(data);
	}
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		if (ctx.mode !== "tui") return;
		ctx.ui.setEditorComponent(
			(tui, theme, keybindings) => new GhosttyShiftEnterEditor(tui, theme, keybindings),
		);
	});
}
