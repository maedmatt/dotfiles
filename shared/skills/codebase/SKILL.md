---
name: codebase
description: "Understand a GitHub repository by analyzing its PR history, architecture, and evolution patterns."
argument-hint: "<owner/repo> [prs|notable|<pr-number>|area:<path>]"
allowed-tools: Bash, Read
---

# Codebase

Understand a GitHub repository through its PR history and structure.

## Arguments

Parse `$ARGUMENTS` to determine the command:

- `<owner/repo>` alone → overview
- `<owner/repo> prs` → list PRs
- `<owner/repo> notable` → find high-signal PRs
- `<owner/repo> <number>` → deep dive into PR
- `<owner/repo> area:<path>` → PRs touching a path

## Commands

### Overview (default)

When only `<owner/repo>` is provided:

1. Fetch repo info:
```bash
gh repo view <repo> --json description,primaryLanguage,stargazerCount,forkCount
```

2. Fetch last 30 merged PRs:
```bash
gh pr list -R <repo> --state merged --limit 30 --json number,title,author,files,mergedAt
```

3. Analyze and report:
   - Repository description and stats
   - Most active directories (count file changes by directory)
   - Top contributors (count PRs by author)
   - Recent activity themes (categorize PR titles)

### List PRs

When `prs` is specified:

```bash
gh pr list -R <repo> --state merged --limit 20 --json number,title,author,files,comments,mergedAt
```

Format as a table:
```
#     Title                              Author      Files  Comments  Merged
1234  Add user authentication            @alice      12     8         2d ago
1233  Fix memory leak in parser          @bob        3      2         3d ago
```

### Notable PRs

When `notable` is specified:

```bash
gh pr list -R <repo> --state merged --limit 50 --json number,title,author,files,comments,body,mergedAt
```

Filter and rank by:
1. Comment count (most discussed)
2. Files touching 5+ directories (architectural)
3. Body length > 500 chars (well-documented)

Output the top 10 most educational PRs with brief explanations of why they're notable.

### PR Deep Dive

When a PR number is specified:

```bash
gh pr view <number> -R <repo> --json title,body,author,files,comments,reviews,mergedAt
```

Extract and present:
- **Title and author**
- **Problem**: First paragraph of body (usually explains the why)
- **Key files**: List files changed, grouped by directory
- **Discussion**: Summarize review comments, focus on substantive feedback
- **Outcome**: What was decided, any follow-up items mentioned

If the description is minimal, also fetch the diff to understand changes:
```bash
gh pr diff <number> -R <repo>
```

### Area Focus

When `area:<path>` is specified:

```bash
gh pr list -R <repo> --state merged --limit 50 --json number,title,author,files,mergedAt
```

Filter PRs where any file path contains `<path>`. Show:
- PRs that touched that area
- When they were merged
- What changed

This reveals the evolution of a specific part of the codebase.

## Output Guidelines

- Use tables for lists of PRs
- Use headers to separate sections
- Include PR numbers as `#1234` for easy reference
- For deep dives, quote notable review comments
- Keep summaries concise but informative
