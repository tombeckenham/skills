---
name: clean-exit
description: Remove this herdr worktree and close the workspace without merging (ends the session).
disable-model-invocation: true
allowed-tools: Bash(herdr worktree remove *)
---

Abandon the current branch: tear down this herdr worktree and workspace without merging anything. The workspace close ends this session, so do all reporting BEFORE the final step.

Steps, in order:

1. If `HERDR_WORKSPACE_ID` is unset, this is not a herdr worktree — stop and say so.
2. Check for work that would be lost: `git status --porcelain` (uncommitted changes) and `git log @{u}..` or, with no upstream, `git log origin/HEAD..` (unpushed commits). If either is non-empty, list it and ask the user to confirm before continuing. Do not commit or push on their behalf.
3. Report: one line naming the branch and worktree being removed. This is the last thing the user will see from this session.
4. Tear down: `herdr worktree remove --workspace "$HERDR_WORKSPACE_ID" --force`. This closes the workspace and ends the session; do nothing after it.
