---
name: approve-exit
description: Approve the current branch's PR with a comment, approve its pending workflow runs, enable auto-merge, then remove this herdr worktree and close the workspace (ends the session).
disable-model-invocation: true
allowed-tools: Bash(gh pr view *) Bash(gh pr review *) Bash(gh run list *) Bash(gh api -X POST repos/*/actions/runs/*/approve) Bash(gh pr merge *) Bash(herdr worktree remove *)
---

Approve the PR checked out in this worktree, let CI run, queue it to merge on green, then tear down this herdr worktree and workspace. The workspace close ends this session, so do all reporting BEFORE the final step.

Steps, in order. Stop and report at the first failure:

1. Preconditions. If `HERDR_WORKSPACE_ID` is unset, this is not a herdr worktree: stop and say so. Find the PR: `gh pr view --json number,url,state,headRefOid,isCrossRepository`. If there is no open PR, stop. If `git status --porcelain` is non-empty, list the changes and ask the user to confirm before continuing, because they will be lost.
2. Approve: `gh pr review --approve --body "<comment>"`. Write the comment from this session's review: a short thank-you plus what was checked. Keep it to 1-3 sentences.
3. Run workflows. Fork PRs wait for maintainer approval before CI runs. List the waiting runs with `gh run list --commit <headRefOid> --status action_required --json databaseId`, then approve each one with `gh api -X POST repos/{owner}/{repo}/actions/runs/<id>/approve`. If there are none, move on.
4. Auto-merge: `gh pr merge --auto --squash`. Do not pass `--delete-branch`, because gh then tries to check out the base branch, which fails in a worktree. If auto-merge is refused (disabled on the repo, or the PR is already mergeable and merges immediately), report exactly what happened.
5. Report: one line with the PR URL, how many workflow runs were approved, and whether auto-merge is armed. This is the last thing the user will see from this session.
6. Tear down: `herdr worktree remove --workspace "$HERDR_WORKSPACE_ID" --force`. This closes the workspace and ends the session. Do nothing after it.
