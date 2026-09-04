# CLAUDE.md

This repository is a Claude Code + Grok Build plugin marketplace. It is not an application.

## Layout

- `.claude-plugin/marketplace.json` — Claude catalog (`name`: `tombeckenham-skills`)
- `.grok-plugin/marketplace.json` — Grok catalog (same plugin list)
- `.grok-plugin/plugin-index.json` — Grok browse metadata; regenerate when skills change
- `plugins/<name>/skills/<name>/SKILL.md` — the skill Grok and Claude load
- `plugins/<name>/plugin.json` and `plugins/<name>/.claude-plugin/plugin.json` — keep identical

## Adding a plugin

1. Create `plugins/<name>/skills/<name>/` with `SKILL.md` (and `scripts/` if the skill runs a helper).
2. Add matching `plugin.json` files (see an existing plugin).
3. Append the plugin to both marketplace files and to `plugin-index.json`.
4. Validate:

```bash
claude plugin validate .
grok plugin validate plugins/<name>
```

Bump `version` in `plugin.json` and both marketplace entries when the skill changes, or installed copies will not update.

## Writing skills

Keep each fact in one place (the `SKILL.md`). Do not restate marketplace descriptions inside the skill body. Frontmatter `description` is the trigger; put "when to use" there, not as a later heading.

## Install (for testers)

```
/plugin marketplace add tombeckenham/skills
/plugin install <plugin>@tombeckenham-skills
```

```bash
grok plugin marketplace add tombeckenham/skills
grok plugin install <plugin> --trust
```
