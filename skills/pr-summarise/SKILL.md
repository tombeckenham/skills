---
name: pr-summarise
description: >-
  Summarise a GitHub pull request as a single decision table so the maintainer
  can action it: what it solves, whether that matters, added complexity,
  fallbacks that should be errors, public type/API changes, users helped and
  hurt, AG-UI and other standards compliance, and an Approve / Fix / Reject
  verdict, plus key files to review by hand, manual test steps, and an interactive HTML
  explainer (before/after, what's to love, what's bad). Use when the user runs /pr-summarise, or asks to "summarise this PR",
  "should I merge this PR", "what does PR N do", or wants a quick verdict on a PR.
---

# pr-summarise

Read one PR, print one table that lets the maintainer decide what to do with it, list the files worth reviewing by hand and how to test it manually, and open an interactive HTML explainer. Read-only on GitHub: never comment, approve, or push. The only thing written is the local HTML file.

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
- **Better / proper fix**: is this the right fix, or is there a better one? Check whether it patches a symptom while the root cause sits elsewhere (grep the other callers of what it touches: are they still broken?), whether it duplicates something the codebase or a dependency already provides, and whether a smaller or more general change would do the same job. Answer "No, this is the proper fix" or describe the better fix in one or two sentences with where it would go.
- **Verdict**: exactly one of
  - **Approve**: correct, worth having, mergeable as is.
  - **Fix**: worth having but needs specific changes first. List them.
  - **Reject**: not worth solving, wrong approach, or costs outweigh the benefit. Say which.

A fallback that should be an error, an unintended breaking change, or a compliance break means the verdict is Fix at best. If a better fix exists, the verdict is Fix (rework it that way) or Reject (the better fix replaces this PR).

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
| Better / proper fix | | |
| **Verdict** | **Approve / Fix / Reject** | one-line reason |
```

If the verdict is Fix, follow the table with a numbered list of the required changes, each with `file:line`.

Then print **Review manually**: the 3 to 7 files where a human's eyes add the most, ranked, each with `path:line-range` and one line on what to check there. Prefer files holding core logic, public API or type changes, fallbacks flagged above, concurrency or security paths, and anything the tests don't cover. Skip lockfiles, generated code, snapshots, and pure renames. If the PR touches fewer files than that, list only the ones that matter.

```markdown
**Review manually**
1. `src/stream.ts:40-88` — new retry loop; check it can't swallow an abort.
2. ...
```

Then print **Test manually**: numbered steps a human can run to see the change work (and see the old bug, if it fixes one). Name the exact commands, inputs, or UI path, and the expected result after the PR versus before it. Include one edge case aimed at the riskiest part found above. Get the setup from the repo (README, `package.json` scripts, examples, tests the PR adds); don't invent commands. If the change can't be exercised by hand (types-only, internal refactor), say so and name the test that covers it.

```markdown
**Test manually**
1. `pnpm --filter example-chat dev`, open http://localhost:3000.
2. Send a message, then hit Stop mid-stream. Expect: stream ends, no error toast (before: "AbortError" toast).
3. Edge case: ...
```

Finish with the path of the HTML explainer. Nothing else: no preamble, no walkthrough of the diff.

## HTML explainer

Write one self-contained file to `${TMPDIR:-/tmp}/pr-<N>-explainer.html` (inline CSS and JS, no external requests), then open it (`open` on macOS, `xdg-open` on Linux). It explains the PR to someone who hasn't read it, in under two minutes. Keep every section short: sentences, not paragraphs.

Sections, in order:

1. **Header**: PR title, link, author, +A/-D, and the verdict as a coloured badge (Approve green, Fix amber, Reject red).
2. **In one breath**: two or three sentences on what changes and why.
3. **Before / After**: a toggle (or tabs) that swaps between the behaviour before and after the PR. For each, a short description plus the most telling code snippet or a small diagram (inline SVG or CSS boxes) of the flow. Pick the one or two changes that best show the difference, not every hunk.
4. **What's to love**: bullet list of the genuine strengths of the design, each tied to a file.
5. **What's bad**: bullet list of design problems, risks, fallbacks that should be errors, and the better fix if there is one, each tied to `file:line`. If there's nothing bad, say so in one line; don't invent problems.
6. **Review manually**: the same file list as the terminal output, each item expandable (`<details>`) to show the relevant diff excerpt.
7. **Test manually**: the same steps as the terminal output, as a checklist (`<input type="checkbox">`) with each command in a code block.

Interactivity stays native: `<details>`, a radio-button or button toggle for before/after, nothing heavier. Follow the system light/dark theme with `prefers-color-scheme`. Escape any code you embed (`<`, `>`, `&`).
