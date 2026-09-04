# CLAUDE.md

This repository is one plugin (`tombeckenham-skills`) that also publishes as a Claude Code + Grok Build marketplace. It is not an application.

## Layout

- `plugin.json` and `.claude-plugin/plugin.json` — keep identical. This is what `grok plugin install tombeckenham/skills` loads.
- `.claude-plugin/marketplace.json` — Claude catalog (one plugin, source `./`)
- `.grok-plugin/marketplace.json` — Grok catalog (same)
- `.grok-plugin/plugin-index.json` — Grok browse metadata
- `skills/<name>/SKILL.md` — skills Grok and Claude load

## Adding a skill

1. Create `skills/<name>/SKILL.md` (and `scripts/` if the skill runs a helper).
2. Bump `version` in `plugin.json` and both marketplace entries.
3. Update `.grok-plugin/plugin-index.json`.
4. Validate:

```bash
claude plugin validate .
grok plugin validate .
```

## Install

```bash
grok plugin install tombeckenham/skills --trust
```

```
/plugin marketplace add tombeckenham/skills
/plugin install tombeckenham-skills@tombeckenham-skills
```
