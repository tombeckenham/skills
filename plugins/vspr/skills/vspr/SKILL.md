---
name: vspr
description: >-
  Print the vscode.dev URL for a GitHub pull request. Do not open a browser.
  Use when the user runs /vspr, or asks for a vscode.dev PR link, "vscode.dev URL
  for this PR", "open this PR in vscode.dev" (return the URL only), or a
  github.dev/vscode.dev link to review a PR in the browser IDE.
---

# vspr

Return a vscode.dev URL for a GitHub PR. Never open it (`open`, `xdg-open`, browser tools).

## Resolve the PR

1. If the user passed a number, `#N`, or `https://github.com/OWNER/REPO/pull/N`, use that.
2. Else use the PR for the current branch:

```bash
gh pr view --json url,number,headRepositoryOwner,headRepository
```

If that fails, stop: no PR on this branch. Tell the user to pass a number or open one.

Owner/repo come from the GitHub URL (`github.com/OWNER/REPO/pull/N`), not from a fork's head repo.

## URL

```
https://vscode.dev/github/OWNER/REPO/pull/N
```

Print that URL as the entire reply (a markdown link is fine). No extra steps.
