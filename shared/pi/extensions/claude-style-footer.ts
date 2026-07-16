import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

function formatTokens(count: number): string {
	if (!Number.isFinite(count) || count <= 0) return "0";
	if (count < 1000) return `${Math.round(count)}`;
	if (count < 10000) return `${(count / 1000).toFixed(1)}k`;
	if (count < 1000000) return `${Math.round(count / 1000)}k`;
	if (count < 10000000) return `${(count / 1000000).toFixed(1)}M`;
	return `${Math.round(count / 1000000)}M`;
}

function formatCwd(cwd: string): string {
	const home = process.env.HOME;
	if (!home) return cwd;
	return cwd === home ? "~" : cwd.startsWith(`${home}/`) ? `~/${cwd.slice(home.length + 1)}` : cwd;
}

function latestCacheHit(ctx: ExtensionContext): number | undefined {
	let latest: number | undefined;

	for (const entry of ctx.sessionManager.getEntries()) {
		if (entry.type !== "message" || entry.message.role !== "assistant") continue;

		const usage = entry.message.usage;
		if (!usage) continue;

		const promptTokens = usage.input + usage.cacheRead + usage.cacheWrite;
		if (promptTokens > 0) {
			latest = (usage.cacheRead / promptTokens) * 100;
		}
	}

	return latest;
}

function describeAgentMode(pi: ExtensionAPI): { label: string; color: "success" | "warning" | "error" | "dim" } {
	const activeTools = pi.getActiveTools();
	const active = new Set(activeTools);
	const readTools = ["read", "grep", "find", "ls"];
	const mutatingTools = ["bash", "edit", "write"];
	const defaultPiTools = ["read", "bash", "edit", "write"];

	if (activeTools.length === 0) return { label: "no-tools mode", color: "error" };
	if (readTools.some((tool) => active.has(tool)) && mutatingTools.every((tool) => !active.has(tool))) {
		return { label: "plan mode on", color: "warning" };
	}
	if (defaultPiTools.every((tool) => active.has(tool))) return { label: "auto mode on", color: "success" };
	return { label: "custom mode on", color: "warning" };
}

export default function (pi: ExtensionAPI) {
	let enabled = true;
	let requestRender: (() => void) | undefined;

	function installFooter(ctx: ExtensionContext) {
		if (ctx.mode !== "tui" || !enabled) return;

		ctx.ui.setFooter((tui, theme, footerData) => {
			requestRender = () => tui.requestRender();
			const unsubscribeBranch = footerData.onBranchChange(() => tui.requestRender());

			return {
				dispose() {
					unsubscribeBranch();
					requestRender = undefined;
				},
				invalidate() {},
				render(width: number): string[] {
					const sep = theme.fg("dim", " │ ");
					const model = ctx.model?.id ?? "no-model";
					const thinking = pi.getThinkingLevel();
					const modelText = thinking && thinking !== "off" ? `${model}:${thinking}` : model;

					const branch = footerData.getGitBranch();
					const cacheHit = latestCacheHit(ctx);
					const cacheText = cacheHit === undefined ? "CH --" : `CH ${cacheHit.toFixed(1)}%`;
					const cacheColor =
						cacheHit === undefined ? "dim" : cacheHit >= 70 ? "success" : cacheHit >= 30 ? "warning" : "error";

					const usage = ctx.getContextUsage();
					const contextWindow = usage?.contextWindow ?? ctx.model?.contextWindow ?? 0;
					const contextPercent = usage?.percent;
					const contextText =
						contextPercent === null || contextPercent === undefined
							? `ctx ?/${formatTokens(contextWindow)}`
							: `ctx ${contextPercent.toFixed(1)}%/${formatTokens(contextWindow)}`;
					const contextColor =
						contextPercent === null || contextPercent === undefined
							? "dim"
							: contextPercent > 85
								? "error"
								: contextPercent > 65
									? "warning"
									: "success";

					const parts = [
						theme.fg("error", theme.bold(modelText)),
						branch ? theme.fg("warning", branch) : undefined,
						theme.fg(cacheColor as never, cacheText),
						theme.fg(contextColor as never, contextText),
					].filter((part): part is string => Boolean(part));

					let topLine = parts.join(sep);
					if (visibleWidth(topLine) > width) {
						const compactParts = [
							theme.fg("error", theme.bold(modelText)),
							theme.fg(cacheColor as never, cacheText),
							theme.fg(contextColor as never, contextText),
						];
						topLine = compactParts.join(sep);
					}

					const agentMode = describeAgentMode(pi);
					const modeLine = [
						theme.fg(agentMode.color as never, "▶▶ "),
						theme.fg(agentMode.color as never, agentMode.label),
						theme.fg("dim", " (shift+tab for thinking)"),
					].join("");

					const cwdLine = theme.fg("customMessageLabel", formatCwd(ctx.cwd));
					return [
						truncateToWidth(topLine, width, theme.fg("dim", "...")),
						truncateToWidth(cwdLine, width, theme.fg("dim", "...")),
						truncateToWidth(modeLine, width, theme.fg("dim", "...")),
					];
				},
			};
		});
	}

	pi.on("session_start", async (_event, ctx) => {
		installFooter(ctx);
	});

	pi.on("model_select", async () => requestRender?.());
	pi.on("thinking_level_select", async () => requestRender?.());
	pi.on("message_end", async () => requestRender?.());
	pi.on("session_info_changed", async () => requestRender?.());

	pi.registerCommand("pi-footer", {
		description: "Toggle the custom cache/context footer",
		handler: async (_args, ctx) => {
			enabled = !enabled;
			if (enabled) {
				installFooter(ctx);
				ctx.ui.notify("Custom pi footer enabled", "info");
			} else {
				ctx.ui.setFooter(undefined);
				ctx.ui.notify("Default pi footer restored", "info");
			}
		},
	});
}
