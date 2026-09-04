---
name: merge-and-exit
description: Wait for the current branch's PR CI to go green, merge it, remove this herdr worktree, and close the workspace (ends the session).
disable-model-invocation: true
allowed-tools: Bash(gh pr checks *) Bash(gh run view *) Bash(gh pr merge *) Bash(herdr worktree remove *)
---

Finish the current branch: merge its PR once CI is green, then tear down this herdr worktree and workspace. The workspace close ends this session, so do all reporting BEFORE the final step.

Steps, in order — stop and report at the first failure:

1. Preconditions. `git status --porcelain` must be empty and the branch must be pushed (`git status -sb` shows no "ahead"). Commit/push first if not. Find the PR: `gh pr view --json number,url,state,mergeStateStatus`. If there is no open PR, stop.
2. Wait for CI: `gh pr checks --watch --fail-fast`. If any check fails, stop and report the failing check (`gh run view --log-failed` for the run) — do not merge, do not remove the worktree.
3. Merge: `gh pr merge --squash --delete-branch`. If the merge is refused (review required, conflicts, `mergeStateStatus` BLOCKED), stop and report why.
4. Report: one line with the PR URL and the merge commit. This is the last thing the user will see from this session.
5. Tear down: `herdr worktree remove --workspace "$HERDR_WORKSPACE_ID" --force`. If `HERDR_WORKSPACE_ID` is unset, this is not a herdr worktree — skip removal and say so. This closes the workspace and ends the session; do nothing after it.
