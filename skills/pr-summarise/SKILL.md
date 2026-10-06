---
name: pr-summarise
description: >-
  Summarise a GitHub pull request as a single decision table so the maintainer
  can action it: what it solves, whether that matters, added complexity,
  fallbacks that should be errors, public type/API changes, users helped and
  hurt, AG-UI and other standards compliance, and an Approve / Fix / Reject
  verdict. Use when the user runs /pr-summarise, or asks to "summarise this PR",
  "should I merge this PR", "what does PR N do", or wants a quick verdict on a PR.
---

# pr-summarise

Read one PR and print one table that lets the maintainer decide what to do with it. Read-only: never comment, approve, or push.

## Resolve the PR

1. If the user passed a number, `#N`, or a PR URL, use that.
2. Else use the PR for the current branch. If there is none, stop and ask for a number.

## Gather

```bash
gh pr view <PR> --json number,title,body,author,url,additions,deletions,changedFiles,files,labels,closingIssuesReferences,reviewDecision,statusCheckRollup
gh pr diff <PR>
```

Read the whole diff, not just the description. Descriptions are claims; the diff is the evidence. Also read:

- Linked issues (`gh issue view N --comments`): reactions and distinct reporters are the best signal for how many users care.
- Surrounding code where the diff alone doesn't show whether something is exported, or what a changed function's callers do.

## Judge

Every answer is backed by the diff. Cite `file:line` in the Evidence column wherever a specific line drives the answer.

- **Solves**: one sentence, in terms of what a user can now do or no longer hits. Not a restatement of the title.
- **Important to solve**: Yes / Somewhat / No. A real bug or blocked use case with reporters is Yes. Speculative, cosmetic, or a single user's preference is No.
- **Adds complexity**: Yes / Slightly / No / Reduces. Count new options, config, branches, abstractions, dependencies, and concepts a user or maintainer must now hold. Net deletion is "Reduces".
- **Fallbacks that should be errors**: list each one. Look for `catch` blocks that swallow or log and continue, `?? default` / `|| default` on values that should be required, optional chaining that hides a missing value, silent retries, and "if unsupported, do something else" branches. A fallback is fine only when the fallback result is still correct; if it hides a caller's mistake or a broken invariant, it should throw.
- **Public type or API changes**: list each changed export, type, function signature, option, event shape, wire format, or CLI flag, marked breaking or additive. "None" only after checking what the changed files export.
- **Users positively affected**: an estimate with its basis, e.g. "Most: every user of `chat()` with streaming" or "Few: only custom adapter authors (1 reporter, 3 thumbs up)". Use Few / Some / Most / All and an approximate figure when the evidence supports one. Don't invent precision.
- **Users negatively affected**: same scale. Count anyone hit by a breaking change, a changed default, a performance cost, or a new required step. "None" is a valid answer.
- **Standards compliance**: does it change behaviour covered by [AG-UI](https://docs.ag-ui.com) (event types, event ordering, message and tool-call shapes) or any other standard or spec the repo follows (check README, CLAUDE.md, docs for claims such as OpenAPI, JSON Schema, MCP, OpenTelemetry, semver, WCAG)? Answer Improves / Neutral / Breaks, naming the standard and the rule. If the repo follows no relevant standard, say "N/A".
- **Verdict**: exactly one of
  - **Approve**: correct, worth having, mergeable as is.
  - **Fix**: worth having but needs specific changes first. List them.
  - **Reject**: not worth solving, wrong approach, or costs outweigh the benefit. Say which.

A fallback that should be an error, an unintended breaking change, or a compliance break means the verdict is Fix at best.

## Output

Print the PR title as a link, then exactly this table, then stop.

```markdown
[#N Title](url) by @author, +A/-D across F files

| | Answer | Evidence |
|---|---|---|
| Solves | | |
| Important to solve | | |
| Adds complexity | | |
| Fallbacks that should be errors | | |
| Public type / API changes | | |
| Users positively affected | | |
| Users negatively affected | | |
| AG-UI / standards compliance | | |
| **Verdict** | **Approve / Fix / Reject** | one-line reason |
```

If the verdict is Fix, follow the table with a numbered list of the required changes, each with `file:line`. Nothing else: no preamble, no walkthrough of the diff.
