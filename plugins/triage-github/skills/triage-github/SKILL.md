---
name: triage-github
description: Triage all open GitHub issues and PRs in the current repository by fanning out up to 100 parallel subagents (one per item), then produce a single prioritized report ranking which PRs to review first and which issues to address first. Use when the user asks to "triage open issues/PRs", "prioritize the backlog", "what should I review first", "what to address first", "sweep the repo", or any request to bulk-evaluate open GitHub work and recommend an order.
---

# Triage GitHub Issues & PRs in Parallel

## When to use

The user wants a prioritized view of everything open on the current repo's GitHub: which PRs to merge/review first, and which issues to fix first. Trigger phrases include "triage the backlog", "what should I look at first", "prioritize open PRs and issues", "sweep open work".

Do **not** invoke for single-item review (just look at it directly) or when the user wants ongoing automation (use `/schedule` instead).

## Prerequisites

- `gh` CLI is authenticated (`gh auth status`). If not, stop and ask the user to authenticate — do not attempt to fix auth automatically.
- Run from inside a git repo whose `origin` points at the GitHub repo to triage. Confirm with `gh repo view --json nameWithOwner`.

## Procedure

### 1. Fetch open work

Run these two `gh` calls in parallel. Use JSON so the downstream agent prompts are self-contained.

```bash
gh pr list --state open --limit 200 --json number,title,url,author,createdAt,updatedAt,isDraft,mergeable,reviewDecision,labels,additions,deletions,changedFiles,statusCheckRollup
gh issue list --state open --limit 200 --json number,title,url,author,createdAt,updatedAt,labels,comments,reactionGroups
```

If either list returns more than 100 items, tell the user the count and ask whether to cap at 100 most-recently-updated or split into batches. The agent cap is 100 total across PRs+issues.

### 2. Decide the parallel split

- Count `nPRs` and `nIssues`.
- If `nPRs + nIssues <= 100`: spawn one agent per item.
- Otherwise: prioritize PRs first (they block contributors), then issues by most-recently-updated, up to the 100 budget. Note in the final report which items were skipped.

### 3. Fan out subagents

Dispatch **all agents in a single message** using multiple `Agent` tool calls (Codex parallelizes when they're in one block). Use `subagent_type: "general-purpose"` and `run_in_background: false` — you need the results synchronously to write the report.

Per-PR prompt template (substitute the bracketed values):

```
Triage GitHub PR [URL]. You have read-only access via `gh` and web tools.

Gather:
- `gh pr view [NUMBER] --json title,body,author,createdAt,updatedAt,isDraft,mergeable,mergeStateStatus,reviewDecision,labels,additions,deletions,changedFiles,statusCheckRollup,comments`
- `gh pr diff [NUMBER]` (skim — don't dump it)
- Recent review comments if any

Return ONLY a JSON object on a single line (no prose, no fences), matching:
{"kind":"pr","number":N,"title":"...","url":"...","author":"...","ageDays":N,"sizeLOC":N,"ciStatus":"passing|failing|pending|none","mergeable":true|false,"reviewState":"approved|changes_requested|review_required|none","draft":true|false,"priority":"P0|P1|P2|P3","reason":"<=140 chars","blockedBy":"<=80 chars or empty","recommendedAction":"merge|review|request-changes|close|wait"}

Priority rubric:
- P0: ready-to-merge (approved + green CI + mergeable + non-draft), or fixes broken main
- P1: small/focused, passing CI, needs review; or bug fix with clear reproduction
- P2: feature work, larger diff, no blockers
- P3: draft, stale (>30 days no activity), or has unresolved conflicts/failures

Be terse. One JSON object. No commentary.
```

Per-issue prompt template:

```
Triage GitHub issue [URL]. Read-only access via `gh`.

Gather:
- `gh issue view [NUMBER] --json title,body,author,createdAt,updatedAt,labels,comments,reactionGroups,assignees`
- Skim comments for repro steps, workarounds, related PRs

Return ONLY a JSON object on one line:
{"kind":"issue","number":N,"title":"...","url":"...","author":"...","ageDays":N,"reactions":N,"comments":N,"hasRepro":true|false,"linkedPR":"<url or empty>","category":"bug|feature|docs|question|chore","priority":"P0|P1|P2|P3","reason":"<=140 chars","recommendedAction":"fix|investigate|answer|close|wait-for-info"}

Priority rubric:
- P0: regression / data loss / security / blocks many users (high reactions + recent activity)
- P1: confirmed bug with reproduction, or high-engagement feature request
- P2: feature requests, minor bugs, docs gaps
- P3: questions, unreproducible, no activity in 60+ days

One JSON object. No commentary.
```

### 4. Aggregate

Collect every agent's JSON line. If an agent returned prose instead of JSON (rare), extract what you can or mark `priority: "P3", reason: "agent parse failed"`.

Sort:
1. PRs by priority (P0→P3), then by `ageDays` ascending within each tier (newer first for P0/P1 to capture momentum; for P3 by oldest first — those are stalest).
2. Issues by priority, then by `reactions + comments` desc within each tier.

### 5. Write the report

Save to `TRIAGE_REPORT.md` at the repo root (or `.agent/triage/TRIAGE_REPORT-YYYY-MM-DD.md` if the repo has a `.agent/` directory). Ask before overwriting an existing report from today.

Report skeleton:

```markdown
# Triage Report — <repo nameWithOwner> — <YYYY-MM-DD>

Scanned **N PRs** and **M issues**. Skipped K items over the 100-agent budget (listed at bottom).

## PRs to review first

### P0 — merge/fix today
- [#NUM Title](url) — <reason>. _Action: <recommendedAction>_

### P1 — review this week
- [#NUM Title](url) — <reason>. _Action: <recommendedAction>_

### P2 — when time permits
<one-line per item>

### P3 — needs author input or close
<one-line per item>

## Issues to address first

### P0 — fix now
- [#NUM Title](url) — <reason>. _Action: <recommendedAction>_

### P1 — schedule this sprint
- [#NUM Title](url) — <reason>. _Action: <recommendedAction>_

### P2 — backlog
<one-line per item>

### P3 — close or ask for info
<one-line per item>

## Skipped (over budget)
<list any items not triaged>

## How this was generated
N parallel triage agents ran via the `triage-github` skill on <date>. Each agent independently scored its item; this report aggregates and ranks them. Priorities are heuristic — sanity-check P0s before acting.
```

### 6. Summarize for the user

After writing the file, give the user a 3–5 line summary: total counts, top 3 PRs to review, top 3 issues to fix, and the report path. Do not paste the full report into chat.

## Notes

- **Cost**: 100 agents is expensive. If `nPRs + nIssues` is small (say <20), just triage them yourself in the main thread instead of fanning out — mention this and proceed.
- **Rate limits**: `gh` shares one auth token; 100 concurrent `gh` calls usually fits inside GitHub's per-hour quota for authenticated users, but if the user has run heavy `gh` traffic recently, batch the agents in two waves of 50.
- **Failed agents**: if an agent times out or returns garbage, include it in the report under a "Triage failures" subsection rather than silently dropping it.
- **Don't take actions**: this skill is read-only. Do not close issues, request changes, merge PRs, or comment. The report is for the human to act on.
