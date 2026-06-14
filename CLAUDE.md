# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

The `alfred` Claude Code plugin marketplace: a single static manifest
(`.claude-plugin/marketplace.json`) that the `claude` CLI consumes to list and
install plugins. **There is no server, build step, language runtime, or binary.**
Each plugin lives in its *own* GitHub repo; this repo only points at them. Editing
a plugin's skill/command/agent means editing that other repo, not this one — here
you only register, validate, and ship the manifest.

The marketplace install handle is `alfred` (the manifest `name`), not the repo
directory name. Users type `@alfred` after a plugin name.

## Commands

```bash
# Validate the manifest (warnings tolerated, hard errors fail)
claude plugin validate .claude-plugin/marketplace.json

# Full smoke cycle: validate → add at local scope → list → cleanup-on-exit
./.claude/skills/run-alfred-marketplace/smoke.sh

# Scaffold a brand-new plugin repo in the parent directory
./scripts/create-skill.sh <name> "<description>" [parent-dir]
```

`smoke.sh` reports `pass=N fail=N`; exit 0 means all checks passed. It adds the
marketplace at **local** scope (writes to gitignored
`.claude/settings.local.json`) and a `trap` removes it on any exit, so a failed
run never leaves the marketplace registered. Requires `jq`.

## Gotchas (these will bite you)

- **`marketplace add .` is rejected — use `add ./`.** The CLI requires a
  `./`-prefixed path, a GitHub `owner/repo`, or a URL. Bare `.` errors with
  "Invalid marketplace source format."
- **`--strict` validation currently fails.** Any `// comment-*` keys in the
  manifest and the missing top-level marketplace `description` surface as
  warnings, which `--strict` promotes to errors. Don't add `--strict` to CI
  until those are resolved.
- **Always use `alfred-intelligence/...` for new plugin sources.** All manifest
  entries now point there (README + `create-skill.sh` already assume it), and
  it's the org this environment can push to. Avoid `Mr-RedHat-fb/...` — that
  owner needs a separate account, and some of its repos (e.g.
  `kostnadsrakning-skill`) don't even exist, which silently breaks install.
- **Private plugin repos need git auth to install.** `smoke.sh` deliberately
  does *not* install plugins — it only verifies the marketplace manifest loads.
- **`marketplace remove` leaves `"extraKnownMarketplaces": {}`** (empty object,
  not deleted) in `.claude/settings.local.json`. Harmless but visible in diffs.

## Adding a plugin

`create-skill.sh` scaffolds a sibling repo with the required layout
(`.claude-plugin/plugin.json` + `skills/<name>/SKILL.md` + README). Author env
vars (`SKILL_AUTHOR_NAME`, `SKILL_AUTHOR_EMAIL`, `SKILL_ORG`, `SKILL_MARKETPLACE`)
override the defaults baked into the script. After pushing that repo to GitHub,
register it by adding a `plugins[]` entry to `marketplace.json` and committing —
the script prints the exact JSON block to paste. A plugin repo's minimum is
`.claude-plugin/plugin.json` plus at least one of `skills/`, `commands/`, or
`agents/`.

The `description` in both `plugin.json` and the manifest entry is what Claude
matches against to decide relevance — make it state what the plugin does *and*
when it should trigger.

## Shipping plugin updates (esp. to claude.ai web)

Clients detect "is there a newer version?" by comparing the `version` field in
the plugin repo's `plugin.json` (semver). **A plugin with no `version`, or an
unchanged one, will not re-fetch** — pushing new SKILL.md text alone is invisible
to installed clients, and claude.ai web caches especially aggressively. So on
every release: bump `version` in the plugin's `plugin.json`, commit, push. New
scaffolds get `"version": "0.1.0"` from `create-skill.sh`; older plugin repos may
still lack the field and need it added once. The marketplace entry itself carries
no version — it's read from the plugin repo `marketplace.json` points at, so that
`repo` owner must match where you actually push.
