# tombeckenham/skills

Personal skills for [Claude Code](https://code.claude.com) and [Grok Build](https://docs.x.ai/build/features/skills-plugins-marketplaces).

## Install

**Grok Build** (one plugin, all six skills):

```bash
grok plugin install tombeckenham/skills --trust
```

Or add as a marketplace first:

```bash
grok plugin marketplace add tombeckenham/skills
grok plugin install tombeckenham-skills --trust
```

**Claude Code**

```
/plugin marketplace add tombeckenham/skills
/plugin install tombeckenham-skills@tombeckenham-skills
```

## Skills

| Skill | What it does |
| --- | --- |
| `/vspr` | Print a `vscode.dev` URL for a GitHub PR. Does not open a browser. |
| `/merge-and-exit` | Squash-merge the current PR after CI is green, then remove the herdr worktree. |
| `/triage-github` | Rank open issues and PRs with parallel subagents. |
| `/triage-github-global` | Same, plus GitHub discussions. |
| `/tanstack` | TanStack CLI reference (scaffold, add-ons, docs lookup). |
| `/copy-html-clipboard` | Copy HTML onto the macOS clipboard as `public.html`. |

## Layout

```
plugin.json                       # Grok `plugin install tombeckenham/skills`
.claude-plugin/plugin.json        # same manifest for Claude
.claude-plugin/marketplace.json
.grok-plugin/marketplace.json
.grok-plugin/plugin-index.json
skills/<name>/SKILL.md
```

## Add a skill

1. Put it at `skills/<name>/SKILL.md` (plus `scripts/` if needed).
2. Run `grok plugin validate .` and `claude plugin validate .`.
