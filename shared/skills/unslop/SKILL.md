---
name: unslop
description: Cut AI tells from any writing.
disable-model-invocation: true
---

# Unslop

Edit text to remove AI patterns. Scan for the patterns below, section by section from the whole text down to punctuation, then rewrite. Preserve meaning and match the intended tone.

## Chat and document

1. **The chat is not the document.** A README, doc, or HTML page written during a chat is for someone who never saw the chat. Carry over the user's ideas, not their phrasing, their tone, or the order the ideas came up in. Cut exploratory asides, labels coined during the chat, and references to the chat such as "as discussed" or "the option above". The result must be self-contained, clear, and easy to read for someone else. State what the subject is before the details, define each term where it first appears, and order the sections for a reader new to the subject.
2. **Chatbot phrases.** "Of course!", "Certainly!", "Great question!", "You're absolutely right!", "I hope this helps!", "Let me know if...", "Found the smoking gun!" Remove them and respond directly.

## Content

3. **Superficial -ing phrases.** "highlighting...", "ensuring...", "reflecting...", "showcasing...", "fostering...". Delete or expand with real sources.
4. **Vague attributions.** "Experts believe", "Industry reports suggest", "Some critics argue". Name the source or delete.
5. **Say what it does, not how it feels.** Name the mechanism or a number. "types that follow your schema" becomes "a column rename fails the build". Cut any sentence you can't restate as an instruction, fact, or number, and any sentence that could appear unchanged in another project's docs. Generic conclusions ("The future looks bright.") fail the same test.

## Sentences

6. **"Not just X, but Y."** State the point directly instead.
7. **Rule of three.** Don't force ideas into groups of three. Use the natural number.
8. **False ranges.** "from X to Y" where X and Y aren't on a meaningful scale. List topics directly.
9. **Shorten or split dense sentences.** If the reader has to backtrack to parse a sentence, break it in two or drop clauses. One idea per sentence.
10. **Active voice.** Prefer it. Catch "is/are/was/were + past participle" and name the actor: "queries are validated" becomes "the compiler validates queries", "the file is parsed by the loader" becomes "the loader parses the file". Passive is fine only when the actor is unknown or genuinely doesn't matter.
11. **Over-compression.** Dropped articles, verbless fragments, symbol-speak, and abbreviations that make the reader decode instead of read. "Parser rejects bad date → exit 2, no write" becomes "The parser rejects a bad date, exits with code 2, and writes nothing." Write whole sentences with their articles and verbs, and spell out arrows and abbreviations.

## Words

12. **Prefer the plain word.** The fancier synonym is rarely clearer. "utilize" and "leverage" become "use", "facilitate" becomes "help", "numerous" becomes "many", and "serves as", "stands as", "boasts", "features" become "is" or "has". Replace AI vocabulary the same way: additionally, crucial, delve, enduring, enhance, fostering, garner, interplay, intricate, landscape (abstract), pivotal, showcase, tapestry (abstract), testament, underscore, vibrant.
13. **Filler phrases.** "In order to" becomes "To". "Due to the fact that" becomes "Because". "In the event that" becomes "If". Delete "It is important to note that".
14. **Excessive hedging.** "could potentially possibly be argued that it might" becomes "may".
15. **Cut adverbs, or use a stronger verb.** "runs quickly" becomes "is fast" or the number, and "significantly improves" becomes the measured delta. An adverb propping up a weak verb means the verb is wrong.
16. **Synonym cycling.** Protagonist, main character, central figure, hero all in one paragraph. Pick one, repeat it.
17. **Literal words, not metaphors.** Use the concrete word or the mechanism's real name. Watch for nouns that only sound technical (substrate, locus, nexus, vantage, bedrock, paradigm, endgame, north star, flywheel, gold-plating) and for words used as metaphors (wedge, vector, primitive, harness, surface as in "API surface", scaffolding, ratchet, modality, "evacuate" for moving code). A term used in its literal technical sense stays, such as a vector in linear algebra or a modality in multimodal learning. Cut mannered prose too: aphorisms ("wire it or delete it"), rhetorical fragments for effect, personified code ("the plan holds it"), figurative verbs ("rides along", "stands on"), and stock framing phrases. "A dial worth turning" becomes "a parameter worth varying".

## Formatting and punctuation

18. **Colon overuse.** Colons are fine before a list or example, not as mid-sentence connectors. "If you're coming from traditional automation: instead of registering event handlers, you describe conditions" adds nothing with the colon. Rewrite to let the point stand on its own without comparison framing. "Describing when the scheduler should fire works best as plain English." Same meaning, no crutch punctuation.
19. **Boldface overuse.** Don't bold every proper noun or acronym.
20. **Inline-header lists.** The tell is a bold label and colon that restates the line: "**Performance:** Performance improved...". Convert those to prose. A bold lead-in that ends in a period, names the item, and is followed by genuinely new detail ("**Schema in TypeScript.** Tables live in one file.") is fine, not a tell.
21. **Title case headings.** Use sentence case.
22. **Decorative emojis.** Remove from headings and bullets.
23. **Curly quotes.** Use straight quotes.
