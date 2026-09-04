---
name: tanstack
description: TanStack CLI reference for scaffolding, add-ons, and documentation lookup. Use when working with TanStack Start/Router projects, adding integrations (auth, database, deployment), searching TanStack docs, or creating new TanStack applications. Replaces the removed TanStack MCP server.
---

# TanStack CLI

The TanStack MCP server has been removed. Use the `tanstack` CLI directly instead.

## Quick Reference

```bash
# Scaffold new app
npx @tanstack/cli create my-app

# Add integrations to existing project
tanstack add <add-on-name>

# Discover add-ons
tanstack create --list-add-ons --framework react --json
tanstack create --addon-details <name> --framework react --json

# Search docs
tanstack search-docs "loaders" --library router --framework react --json
tanstack doc <library> <doc-path> --json

# Browse libraries and ecosystem
tanstack libraries --json
tanstack ecosystem --category auth --json
```

## Commands

### `tanstack create [project-name]`
Scaffold a new TanStack Start/Router app (SSR by default).

Flags: `--add-ons`, `--template`, `--framework`, `--router-only`, `--toolchain`, `--deployment`, `--package-manager`, `--list-add-ons`, `--addon-details <name>`, `--json`, `--force`, `--no-install`

### `tanstack add [add-on...]`
Add integrations to an existing project. Use `--forced` to override conflicts.

Add-ons install source code in `src/integrations/`, demo routes in `src/routes/demo/`, merge dependencies, inject providers/plugins via hooks, and add env vars to `.env.example`.

### `tanstack search-docs <query>`
Search across TanStack documentation. Filters: `--library`, `--framework`, `--limit` (default 10, max 50). Always use `--json`.

### `tanstack doc <library> <path>`
Fetch a specific docs page. Use `--docs-version` for versioned docs. Always use `--json`.

### `tanstack libraries`
List TanStack libraries. Filter by group: state, headlessUI, performance, tooling. Use `--json`.

### `tanstack ecosystem`
Browse partner tools. Filter by `--category` or TanStack library. Use `--json`.

### `tanstack pin-versions`
Remove caret ranges from TanStack packages and add missing peer dependencies.

### `tanstack add-on init|compile` / `tanstack template init|compile`
Author custom add-ons or templates.

## Configuration

Projects include `.tanstack.json` with: version, name, framework, mode, TypeScript, Tailwind, package manager, and selected add-ons.

## Key Rules

- Always pass `--json` when using CLI output programmatically
- Use `tanstack search-docs` instead of the removed MCP `search_docs` tool
- Use `tanstack create --list-add-ons` instead of the removed MCP `list_addons` tool
- This project uses `bun` as package manager — pass `--package-manager bun` when scaffolding
