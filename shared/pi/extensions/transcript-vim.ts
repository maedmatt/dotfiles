import type { AssistantMessage, ToolCall, ToolResultMessage } from "@earendil-works/pi-ai";
import {
	copyToClipboard,
	CustomEditor,
	getMarkdownTheme,
	type ExtensionAPI,
	type ExtensionContext,
	type KeybindingsManager,
	type SessionEntry,
	type Theme,
} from "@earendil-works/pi-coding-agent";
import {
	isKeyRelease,
	Key,
	Markdown,
	matchesKey,
	truncateToWidth,
	visibleWidth,
	wrapTextWithAnsi,
	type Component,
	type EditorTheme,
	type TUI,
} from "@earendil-works/pi-tui";
import { stripVTControlCharacters } from "node:util";

type TranscriptBlock = {
	id: string;
	kind: "assistant" | "tool";
	title: string;
	body: string;
	copyText: string;
	metaText: string;
	isError?: boolean;
};

type ToolBlock = TranscriptBlock & {
	kind: "tool";
	call: ToolCall;
	result?: ToolResultMessage;
};

function clean(text: string): string {
	return stripVTControlCharacters(text)
		.replace(/\r\n?/g, "\n")
		.replace(/[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/g, "");
}

function stringify(value: unknown): string {
	try {
		return JSON.stringify(value, null, 2);
	} catch {
		return String(value);
	}
}

function contentText(content: ToolResultMessage["content"]): string {
	return content
		.map((part) => (part.type === "text" ? part.text : `[${part.mimeType} image]`))
		.join("\n");
}

function toolSummary(call: ToolCall): string {
	const args = call.arguments as Record<string, unknown>;
	const detail = [args.path, args.command, args.query, args.pattern].find(
		(value): value is string => typeof value === "string" && value.length > 0,
	);
	if (!detail) return call.name;
	const oneLine = detail.replace(/\s+/g, " ");
	return `${call.name} ${oneLine.length > 70 ? `${oneLine.slice(0, 67)}...` : oneLine}`;
}

function updateToolBlock(block: ToolBlock): void {
	const input = clean(stringify(block.call.arguments));
	const output = block.result ? clean(contentText(block.result.content)) : "Waiting for result";
	block.body = `Input\n${input}\n\nOutput\n${output}`;
	block.copyText = block.result ? output : input;
	block.metaText = `${block.call.name} ${stringify(block.call.arguments)}`;
	block.isError = block.result?.isError;
}

function collectTranscriptBlocks(entries: SessionEntry[]): TranscriptBlock[] {
	const blocks: TranscriptBlock[] = [];
	const tools = new Map<string, ToolBlock>();

	for (const entry of entries) {
		if (entry.type !== "message") continue;

		if (entry.message.role === "assistant") {
			const message = entry.message as AssistantMessage;
			for (const [index, part] of message.content.entries()) {
				if (part.type === "text" && part.text.trim()) {
					const body = clean(part.text);
					blocks.push({
						id: `${entry.id}:text:${index}`,
						kind: "assistant",
						title: `assistant · ${message.model}`,
						body,
						copyText: body,
						metaText: `${message.provider}/${message.model}`,
					});
				} else if (part.type === "toolCall") {
					const block: ToolBlock = {
						id: part.id,
						kind: "tool",
						title: `tool · ${toolSummary(part)}`,
						body: "",
						copyText: "",
						metaText: "",
						call: part,
					};
					updateToolBlock(block);
					blocks.push(block);
					tools.set(part.id, block);
				}
			}
		} else if (entry.message.role === "toolResult") {
			const result = entry.message as ToolResultMessage;
			const block = tools.get(result.toolCallId);
			if (block) {
				block.result = result;
				updateToolBlock(block);
				continue;
			}

			const body = clean(contentText(result.content));
			blocks.push({
				id: result.toolCallId,
				kind: "tool",
				title: `tool · ${result.toolName}`,
				body,
				copyText: body,
				metaText: result.toolName,
				isError: result.isError,
			});
		}
	}

	return blocks;
}

class TranscriptBrowser implements Component {
	private selected: number;
	private expanded = new Set<string>();
	private linePositions = new Map<string, number>();
	private bodyLengths = new Map<string, number>();
	private viewportTop = 0;
	private contentHeight = 1;
	private lastBodyWidth = 80;
	private pendingGUntil = 0;
	private notice = "";

	constructor(
		private readonly tui: TUI,
		private readonly theme: Theme,
		private readonly blocks: TranscriptBlock[],
		private readonly close: () => void,
		private readonly openFork: () => void,
		private readonly doubleEscapeUntil: number,
	) {
		const lastAssistant = blocks.findLastIndex((block) => block.kind === "assistant");
		this.selected = lastAssistant >= 0 ? lastAssistant : blocks.length - 1;
		const selected = blocks[this.selected];
		if (selected) this.expanded.add(selected.id);
	}

	private selectedBlock(): TranscriptBlock | undefined {
		return this.blocks[this.selected];
	}

	private moveBlock(delta: number): void {
		this.selected = Math.max(0, Math.min(this.blocks.length - 1, this.selected + delta));
		this.notice = "";
		this.tui.requestRender();
	}

	private bodyLength(block: TranscriptBlock): number {
		const known = this.bodyLengths.get(block.id);
		if (known !== undefined) return known;
		const length = Math.max(1, this.bodyLines(block, this.lastBodyWidth).length);
		this.bodyLengths.set(block.id, length);
		return length;
	}

	private moveLine(delta: number): void {
		const block = this.selectedBlock();
		if (!block) return;
		if (!this.expanded.has(block.id)) {
			this.notice = "Collapsed. Press l to expand";
			this.tui.requestRender();
			return;
		}

		const max = this.bodyLength(block) - 1;
		const current = this.linePositions.get(block.id) ?? 0;
		this.linePositions.set(block.id, Math.max(0, Math.min(max, current + delta)));
		this.notice = "";
		this.tui.requestRender();
	}

	private jumpLine(toEnd: boolean): void {
		const block = this.selectedBlock();
		if (!block || !this.expanded.has(block.id)) return;
		const max = this.bodyLength(block) - 1;
		this.linePositions.set(block.id, toEnd ? max : 0);
		this.notice = "";
		this.tui.requestRender();
	}

	private setExpanded(expanded: boolean): void {
		const block = this.selectedBlock();
		if (!block) return;
		if (expanded) this.expanded.add(block.id);
		else this.expanded.delete(block.id);
		this.notice = "";
		this.tui.requestRender();
	}

	private copy(metadata: boolean): void {
		const block = this.selectedBlock();
		if (!block) return;
		const text = metadata ? block.metaText : block.copyText;
		void copyToClipboard(text)
			.then(() => {
				this.notice = metadata ? "Copied invocation" : "Copied output";
				this.tui.requestRender();
			})
			.catch(() => {
				this.notice = "Copy failed";
				this.tui.requestRender();
			});
	}

	handleInput(data: string): void {
		const now = Date.now();
		if (matchesKey(data, "g")) {
			if (now <= this.pendingGUntil) {
				this.pendingGUntil = 0;
				this.jumpLine(false);
			} else {
				this.pendingGUntil = now + 800;
				this.notice = "g";
				this.tui.requestRender();
			}
			return;
		}
		this.pendingGUntil = 0;
		if (this.notice === "g") this.notice = "";

		const halfPage = Math.max(1, Math.floor(this.contentHeight / 2));
		const fullPage = Math.max(1, this.contentHeight - 1);

		if (matchesKey(data, "shift+j")) this.moveBlock(1);
		else if (matchesKey(data, "shift+k")) this.moveBlock(-1);
		else if (matchesKey(data, "j") || matchesKey(data, Key.down) || matchesKey(data, Key.ctrl("j"))) this.moveLine(1);
		else if (matchesKey(data, "k") || matchesKey(data, Key.up) || matchesKey(data, Key.ctrl("k"))) this.moveLine(-1);
		else if (matchesKey(data, "shift+g") || matchesKey(data, Key.end)) this.jumpLine(true);
		else if (matchesKey(data, Key.home)) this.jumpLine(false);
		else if (matchesKey(data, "h") || matchesKey(data, Key.left)) this.setExpanded(false);
		else if (matchesKey(data, "l") || matchesKey(data, Key.right)) this.setExpanded(true);
		else if (matchesKey(data, Key.enter)) {
			const block = this.selectedBlock();
			if (block) this.setExpanded(!this.expanded.has(block.id));
		} else if (matchesKey(data, Key.ctrl("d"))) this.moveLine(halfPage);
		else if (matchesKey(data, Key.ctrl("u"))) this.moveLine(-halfPage);
		else if (matchesKey(data, Key.pageDown)) this.moveLine(fullPage);
		else if (matchesKey(data, Key.pageUp)) this.moveLine(-fullPage);
		else if (matchesKey(data, "y")) this.copy(false);
		else if (matchesKey(data, "shift+y")) this.copy(true);
		else if (matchesKey(data, Key.escape)) {
			this.close();
			if (now <= this.doubleEscapeUntil) queueMicrotask(this.openFork);
		} else if (matchesKey(data, "q") || matchesKey(data, "i") || matchesKey(data, Key.tab)) {
			this.close();
		}
	}

	private bodyLines(block: TranscriptBlock, width: number): string[] {
		if (block.kind === "assistant") {
			return new Markdown(block.body, 0, 0, getMarkdownTheme()).render(width);
		}
		return wrapTextWithAnsi(block.body, width);
	}

	render(width: number): string[] {
		const height = Math.max(7, this.tui.terminal.rows - 6);
		const contentHeight = height - 3;
		this.contentHeight = contentHeight;
		const bodyWidth = Math.max(1, width - 4);
		this.lastBodyWidth = bodyWidth;
		const rendered: string[] = [];
		const targets: number[] = [];

		for (const [index, block] of this.blocks.entries()) {
			targets[index] = rendered.length;
			const marker = index === this.selected ? "▶ " : "  ";
			const fold = this.expanded.has(block.id) ? "▾ " : "▸ ";
			const color = block.isError ? "error" : index === this.selected ? "accent" : "muted";
			let header = truncateToWidth(`${marker}${fold}${block.title}`, width, "", true);
			header = this.theme.fg(color, header);
			if (index === this.selected) header = this.theme.bg("selectedBg", header);
			rendered.push(header);

			if (this.expanded.has(block.id)) {
				const body = this.bodyLines(block, bodyWidth);
				if (body.length === 0) body.push("");
				this.bodyLengths.set(block.id, body.length);
				const current = Math.max(0, Math.min(body.length - 1, this.linePositions.get(block.id) ?? 0));
				this.linePositions.set(block.id, current);

				for (const [lineIndex, line] of body.entries()) {
					const isCurrent = index === this.selected && lineIndex === current;
					if (isCurrent) targets[index] = rendered.length;
					const prefix = isCurrent ? this.theme.fg("accent", "  ▎ ") : "    ";
					rendered.push(truncateToWidth(`${prefix}${line}`, width, ""));
				}
			}
			rendered.push("");
		}

		const maxTop = Math.max(0, rendered.length - contentHeight);
		const target = targets[this.selected] ?? 0;
		if (target < this.viewportTop || target >= this.viewportTop + contentHeight) {
			this.viewportTop = target - Math.floor(contentHeight / 3);
		}
		this.viewportTop = Math.max(0, Math.min(maxTop, this.viewportTop));

		const label = ` TRANSCRIPT ${this.selected + 1}/${this.blocks.length} `;
		const top = this.theme.fg(
			"accent",
			truncateToWidth(label + "─".repeat(Math.max(0, width - visibleWidth(label))), width, ""),
		);
		const lines = [top];
		const visible = rendered.slice(this.viewportTop, this.viewportTop + contentHeight);
		lines.push(...visible);
		while (lines.length < height - 2) lines.push("");

		const selected = this.selectedBlock();
		const expanded = selected ? this.expanded.has(selected.id) : false;
		const current = selected ? (this.linePositions.get(selected.id) ?? 0) + 1 : 0;
		const total = selected ? (this.bodyLengths.get(selected.id) ?? 0) : 0;
		const position = expanded ? ` block ${this.selected + 1}/${this.blocks.length} · line ${current}/${total} ` : ` block ${this.selected + 1}/${this.blocks.length} · collapsed `;
		lines.push(
			this.theme.fg(
				"dim",
				truncateToWidth("─".repeat(Math.max(0, width - visibleWidth(position))) + position, width, ""),
			),
		);
		const help = this.notice || "j/k lines  J/K blocks  h/l fold  ctrl+u/d page  gg/G ends  y/Y copy  esc prompt";
		lines.push(this.theme.fg(this.notice === "Copy failed" ? "error" : "dim", truncateToWidth(help, width)));
		return lines;
	}

	invalidate(): void {}
}

class TranscriptActivationEditor extends CustomEditor {
	constructor(
		tui: TUI,
		theme: EditorTheme,
		keybindings: KeybindingsManager,
		private readonly activate: (text: string) => boolean,
		private readonly beforeForkPicker: () => void,
	) {
		super(tui, theme, keybindings);
	}

	openForkPicker(): void {
		const open = this.actionHandlers.get("app.session.fork");
		if (!open) return;
		this.beforeForkPicker();
		open();
	}

	handleInput(data: string): void {
		// Ghostty reports Shift+Enter as Alt+Enter in Pi's Kitty keyboard mode.
		if (matchesKey(data, "alt+enter")) {
			super.handleInput("\n");
			return;
		}
		if (matchesKey(data, Key.escape) && !this.isShowingAutocomplete() && this.activate(this.getText())) return;
		super.handleInput(data);
	}
}

async function openTranscript(
	ctx: ExtensionContext,
	openFork: () => void,
	doubleEscapeUntil: number,
): Promise<void> {
	const blocks = collectTranscriptBlocks(ctx.sessionManager.buildContextEntries());
	if (blocks.length === 0) {
		ctx.ui.notify("No assistant output or tool calls in this session", "info");
		return;
	}

	await ctx.ui.custom<void>(
		(tui, theme, _keybindings, done) =>
			new TranscriptBrowser(tui, theme, blocks, () => done(), openFork, doubleEscapeUntil),
		{
			overlay: true,
			overlayOptions: { anchor: "top-center", width: "100%", maxHeight: "100%", margin: 0 },
		},
	);
}

export default function (pi: ExtensionAPI) {
	let browsing = false;
	let forkPickerOpen = false;
	let editor: TranscriptActivationEditor | undefined;
	let unsubscribeInput: (() => void) | undefined;

	pi.on("session_start", (_event, ctx) => {
		if (ctx.mode !== "tui") return;

		unsubscribeInput?.();
		unsubscribeInput = ctx.ui.onTerminalInput((data) => {
			if (!forkPickerOpen || isKeyRelease(data)) return;
			if (matchesKey(data, "j")) return { data: "\x1b[B" };
			if (matchesKey(data, "k")) return { data: "\x1b[A" };
			if (matchesKey(data, Key.enter) || matchesKey(data, Key.escape) || matchesKey(data, Key.ctrl("c"))) {
				forkPickerOpen = false;
			}
		});

		ctx.ui.setEditorComponent((tui, theme, keybindings) => {
			editor = new TranscriptActivationEditor(
				tui,
				theme,
				keybindings,
				(text) => {
					if (browsing || text.trimStart().startsWith("!")) return false;
					browsing = true;
					void openTranscript(ctx, () => editor?.openForkPicker(), Date.now() + 500).finally(() => {
						browsing = false;
					});
					return true;
				},
				() => {
					forkPickerOpen = ctx.sessionManager
						.getBranch()
						.some((entry) => entry.type === "message" && entry.message.role === "user");
				},
			);
			return editor;
		});
	});

	pi.on("session_shutdown", () => {
		unsubscribeInput?.();
		unsubscribeInput = undefined;
		forkPickerOpen = false;
	});
}
