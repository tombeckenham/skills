---
name: pr-fix
description: Make the fixes a PR needs (from this session's pr-summarise Fix list, or what the user asks for), commit and push them to the PR author's branch, approve the PR's pending workflow runs, then run pr-summarise again for a fresh verdict. Use when the user runs /pr-fix, or says "fix this PR and push", "push the fixes to their branch".
disable-model-invocation: true
allowed-tools: Bash(gh pr view *) Bash(gh pr diff *) Bash(gh run list *) Bash(gh api -X POST repos/*/actions/runs/*/approve) Bash(git status *) Bash(git diff *) Bash(git add *) Bash(git commit *) Bash(git push *) Bash(git rev-parse *) Bash(git log *)
---

# pr-fix

Fix the PR checked out here, push the fix to the author's branch, let CI run, then re-summarise. Stop and report at the first failure.

## 1. Preconditions

- PR: the number or URL the user passed, else the current branch's PR. Get it with `gh pr view <PR> --json number,url,state,headRefName,headRefOid,headRepository,headRepositoryOwner,isCrossRepository,maintainerCanModify`. Stop if it isn't open.
- The checked-out branch must be the PR head: `git rev-parse HEAD` equals `headRefOid`. If not, stop and say so; don't check out over the user's work.
- Same-repo PR (`isCrossRepository: false`, e.g. a maintainer's branch): no permission checks needed, `maintainerCanModify` doesn't apply. Carry on.
- Fork PR with `maintainerCanModify: false`: stop. The push will be refused; tell the user to ask the author to enable "Allow edits by maintainers", or to post the fixes as review suggestions instead.

## 2. Fix

What to fix, in priority order:

1. What the user said in this request.
2. The numbered Fix list from this session's pr-summarise run.
3. Neither exists: stop and ask. Don't guess at fixes.

Make the smallest change that resolves each item, in the author's style. Don't refactor beyond the list. Run the repo's checks that cover the touched code (typecheck, lint, the relevant tests, from `package.json` scripts or the README) and fix any failures you caused. If a check fails for a reason unrelated to your change, note it and carry on.

## 3. Commit and push

- `git status --porcelain`: commit only files you changed for the fix. If anything else is dirty, leave it out and mention it.
- One commit, message `Fix: <short summary>` with one body line per item fixed.
- Push to the author's branch, never a new branch:
  - Same repo: `git push origin HEAD:<headRefName>`.
  - Fork: `git push https://github.com/<headRepositoryOwner.login>/<headRepository.name>.git HEAD:<headRefName>`.
- Never force-push. If the push is rejected because the author pushed meanwhile, stop and report; don't rebase their work.

## 4. Approve workflows

Same-repo PR: skip this step, CI starts on its own. Fork PRs wait for maintainer approval before CI runs. Re-read the new head SHA (`git rev-parse HEAD`), list waiting runs with `gh run list --commit <sha> --status action_required --json databaseId`, and approve each with `gh api -X POST repos/{owner}/{repo}/actions/runs/<id>/approve`. Runs can take a few seconds to appear after the push: if none are listed, check once more before moving on.

## 5. Re-summarise

Report one line: commit SHA, items fixed, workflow runs approved. Then run the pr-summarise skill on the same PR and print its output as normal. Don't wait for CI to finish; pr-summarise shows check status as it stands.
