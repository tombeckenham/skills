# tombeckenham/skills

Personal skills for [Claude Code](https://code.claude.com) and [Grok Build](https://docs.x.ai/build/features/skills-plugins-marketplaces), shipped as a plugin marketplace.

## Install

**Claude Code**

```
/plugin marketplace add tombeckenham/skills
/plugin install vspr@tombeckenham-skills
```

**Grok Build**

```bash
grok plugin marketplace add tombeckenham/skills
grok plugin install vspr --trust
```

Local checkout (this folder):

```
/plugin marketplace add ./
```

```bash
grok plugin marketplace add .
```

Install each plugin you want. Names: `vspr`, `merge-and-exit`, `triage-github`, `triage-github-global`, `tanstack`, `copy-html-clipboard`.

## Plugins

| Plugin | Skill | What it does |
| --- | --- | --- |
| `vspr` | `/vspr` | Print a `vscode.dev` URL for a GitHub PR. Does not open a browser. |
| `merge-and-exit` | `/merge-and-exit` | Squash-merge the current PR after CI is green, then remove the herdr worktree. |
| `triage-github` | `/triage-github` | Rank open issues and PRs with parallel subagents. |
| `triage-github-global` | `/triage-github-global` | Same, plus GitHub discussions. |
| `tanstack` | `/tanstack` | TanStack CLI reference (scaffold, add-ons, docs lookup). |
| `copy-html-clipboard` | `/copy-html-clipboard` | Copy HTML onto the macOS clipboard as `public.html`. |

## Layout

```
.claude-plugin/marketplace.json   # Claude catalog
.grok-plugin/marketplace.json     # Grok catalog
.grok-plugin/plugin-index.json    # Grok browse metadata
plugins/<name>/
  plugin.json
  .claude-plugin/plugin.json
  skills/<name>/SKILL.md
```

Grok also reads the Claude catalog. Keep both files in sync when you add a plugin.

## Add a skill

1. Put the skill at `plugins/<name>/skills/<name>/SKILL.md` (plus `scripts/` if needed).
2. Copy an existing `plugin.json` / `.claude-plugin/plugin.json` and change `name` + `description`.
3. Append an entry to both marketplace files (and `.grok-plugin/plugin-index.json`).
4. Run `claude plugin validate .` and `grok plugin validate plugins/<name>`.
