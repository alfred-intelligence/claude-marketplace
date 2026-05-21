---
name: run-alfred-marketplace
description: Validate, smoke-test, and run the alfred Claude Code marketplace. Use when asked to validate the marketplace manifest, run or test the marketplace, smoke-test plugin install/load, or verify the marketplace from a clean state.
---

This repo is a **Claude Code plugin marketplace** (`alfred`) — a static
`.claude-plugin/marketplace.json` manifest consumed by the `claude` CLI.
There is no server, GUI, or binary to launch. "Running" it means:

1. Validating the manifest with `claude plugin validate`.
2. Adding it as a marketplace at local scope, listing it, and removing
   it — the smoke cycle.

Drive it via `.claude/skills/run-alfred-marketplace/smoke.sh`. The script
runs the full cycle with a trap-based cleanup so a failed run never
leaves the marketplace registered.

All paths below are relative to the repo root.

## Prerequisites

- `claude` CLI v2.1.x (verified on 2.1.146) — provides `claude plugin
  validate` / `claude plugin marketplace ...`.
- `jq` — the driver uses it to read the manifest and parse list output.

```bash
sudo apt-get install -y jq
```

No language runtime or build step. Nothing to install in the repo.

## Run (agent path)

```bash
./.claude/skills/run-alfred-marketplace/smoke.sh
```

The script runs four checks and reports `pass=N fail=N` at the end.
Exit 0 means everything passed.

| step | what it does |
|---|---|
| validate | `claude plugin validate .claude-plugin/marketplace.json` — warnings are tolerated, hard errors fail |
| add | `claude plugin marketplace add ./ --scope local` — writes to `.claude/settings.local.json` (gitignored) |
| list | `claude plugin marketplace list --json` filtered by name — confirms the manifest loaded |
| plugins | counts entries in `plugins[]` from the manifest |

Cleanup (`claude plugin marketplace remove alfred`) runs on any exit via
`trap`, including failure or `Ctrl-C`. The local scope means the only
side effect during the run is `.claude/settings.local.json` gaining and
losing an `extraKnownMarketplaces.alfred` entry.

### Smaller one-liners

Just validate:

```bash
claude plugin validate .claude-plugin/marketplace.json
```

Strict mode (warnings → errors; useful in CI):

```bash
claude plugin validate --strict .claude-plugin/marketplace.json
```

Manual add/list/remove cycle if you want to inspect state between steps:

```bash
claude plugin marketplace add ./ --scope local
claude plugin marketplace list --json
claude plugin marketplace remove alfred
```

## Run (human path)

Users install the marketplace from the GitHub remote, not a local path:

```
/plugin marketplace add alfred-intelligence/claude-marketplace
/plugin install kebab-it@alfred
```

This is what the README documents and what end users will actually run.
The local-scope smoke test above exists so you can verify the manifest
**before** pushing, without touching the user's global config.

## Gotchas

- **`marketplace add .` is rejected; `add ./` works.** The CLI requires
  a `./`-prefixed path, GitHub `owner/repo`, or a URL — bare `.` errors
  out with "Invalid marketplace source format."
- **The manifest uses `// comment-*` keys for TODO notes** (intentional;
  there is no `description` field on the marketplace yet). They show as
  unknown-field warnings under `validate` and **fail `--strict`**. Either
  strip them before strict-validating, or don't add `--strict` to CI
  until those notes move into a real `description` / out of the file.
- **`claude plugin install kebab-it@alfred` needs git auth** —
  `alfred-intelligence/kebab-it` is a private GitHub repo. The smoke
  script deliberately does **not** install plugins for this reason;
  it only verifies that the marketplace itself loads.
- **`marketplace remove` leaves `"extraKnownMarketplaces": {}`** as an
  empty object in `.claude/settings.local.json` rather than deleting the
  key. Harmless, but be aware if you diff that file.
- **The marketplace `name` is `alfred`, not `claude-marketplace`.** The
  repo directory name is unrelated to the install handle — users type
  `@alfred` after the plugin name.

## Troubleshooting

- **`✘ Invalid marketplace source format`**: you passed `.` to
  `marketplace add`. Use `./` instead.
- **`Validation failed (--strict treats warnings as errors)`** with only
  `// comment-*` and "No marketplace description" warnings: that's the
  current manifest state — see Gotchas. Drop `--strict` or fix the
  manifest.
- **`Successfully added` but `list` doesn't show it**: you almost
  certainly added at a different scope than you're listing in.
  `list` shows all scopes; if it's missing, the add silently no-op'd —
  re-run with `--scope local` and check the exit code.
