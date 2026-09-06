import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const buildContinuationPrompt = (sessionFile: string | undefined, compactionEntryId: string): string => {
	const sessionSource =
		sessionFile === undefined
			? "This session is ephemeral, so no persisted session file is available."
			: [
					`The persisted session JSONL is ${JSON.stringify(sessionFile)}.`,
					"Inspect it directly with the read and bash tools.",
					"Do not launch a nested Pi process or open the session with `pi --session`.",
				].join(" ");

	return `Compaction has just completed. First decide whether the task that was in progress had already finished before compaction: if it had, say so and stop. Otherwise resume it rather than waiting for another user prompt.

${sessionSource}
The new compaction entry ID is ${JSON.stringify(compactionEntryId)}.

Recover from the session history what the compaction summary may have lost: the original goal, the user's constraints, decisions made, files changed, commands and tests run, unresolved issues, and the intended next step. The messages and tool calls just before the compaction entry matter most. JSONL append order includes abandoned branches, so follow parentId links to stay on the active branch. The current worktree is authoritative for file state; the session history is authoritative for user intent.

State briefly what you recovered, then do the next unfinished step. Ask the user to repeat context only if the session data is unavailable or ambiguous.`;
};

/**
 * Resumes work after successful Pi compactions that do not already trigger an
 * automatic retry. Deferring by one event-loop turn lets manual compaction
 * reconnect the agent runtime before the new prompt begins.
 */
export default function continueAfterCompaction(pi: ExtensionAPI): void {
	const pendingTimers = new Set<ReturnType<typeof setTimeout>>();

	pi.on("session_compact", (event, ctx) => {
		if (event.willRetry) return;

		const sessionFile = ctx.sessionManager.getSessionFile();
		const prompt = buildContinuationPrompt(sessionFile, event.compactionEntry.id);

		const timer = setTimeout(() => {
			pendingTimers.delete(timer);
			pi.sendUserMessage(prompt, { deliverAs: "followUp" });
		}, 0);

		pendingTimers.add(timer);
	});

	pi.on("session_shutdown", () => {
		for (const timer of pendingTimers) clearTimeout(timer);
		pendingTimers.clear();
	});
}
