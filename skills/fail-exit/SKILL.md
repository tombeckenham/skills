---
name: fail-exit
description: Post review feedback asking for changes on the current branch's PR as a plain comment review (never "Request changes", which blocks other maintainers from approving), then remove this herdr worktree and close the workspace (ends the session).
disable-model-invocation: true
allowed-tools: Bash(gh pr view *) Bash(gh pr review *) Bash(gh api repos/*/pulls/*/reviews *) Bash(herdr worktree remove *)
---

Send the PR in this worktree back to its author with review feedback, then tear down this herdr worktree and workspace. The workspace close ends this session, so do all reporting BEFORE the final step.

Never use `--request-changes` or the `REQUEST_CHANGES` event. A changes-requested review blocks merging until the same reviewer dismisses it, so other maintainers can't approve past it. Always post with event `COMMENT`.

Steps, in order. Stop and report at the first failure:

1. Preconditions. If `HERDR_WORKSPACE_ID` is unset, this is not a herdr worktree: stop and say so. Find the PR: `gh pr view --json number,url,state,headRefOid`. If there is no open PR, stop. If `git status --porcelain` is non-empty, list the changes and ask the user to confirm before continuing, because they will be lost.
2. Write the feedback from this session's review:
   - Summary body: thank the author, say that changes are needed before merge, and list the blocking items. Keep it short and specific.
   - Inline comments: one per finding tied to a line in the diff (`path`, `line` in the new file, `side: "RIGHT"`, `body`). Leave out findings that aren't tied to a line; they go in the summary.
   Show the user the summary and the inline comments and wait for their OK before posting.
3. Post one review with event `COMMENT`:
   - Summary only: `gh pr review --comment --body "<summary>"`.
   - With inline comments: write `{"commit_id": "<headRefOid>", "event": "COMMENT", "body": "<summary>", "comments": [...]}` to a temp file, then run `gh api repos/{owner}/{repo}/pulls/<number>/reviews -X POST --input <file>`. If GitHub rejects a line ("line could not be resolved"), move that comment into the summary and retry.
4. Report: one line with the PR URL and the number of inline comments posted. This is the last thing the user will see from this session.
5. Tear down: `herdr worktree remove --workspace "$HERDR_WORKSPACE_ID" --force`. This closes the workspace and ends the session. Do nothing after it.
