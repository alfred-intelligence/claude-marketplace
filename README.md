# alfred

Private Claude Code plugin marketplace for the alfred-intelligence organization.

## Install the marketplace

```
/plugin marketplace add alfred-intelligence/claude-marketplace
```

Then install a plugin:

```
/plugin install kostnadsrakning@alfred
/plugin install kebab-it@alfred
/plugin install project-design@alfred
```

## Plugins

| Name | Description | Source |
|---|---|---|
| `kostnadsrakning` | Svenska rättegångskostnadsräkningar som PDF | [kostnadsrakning-skill](https://github.com/alfred-intelligence/kostnadsrakning-skill) |
| `kebab-it` | Infrastructure change-tasks (GitOps) | [kebab-it](https://github.com/alfred-intelligence/kebab-it) |
| `project-design` | Software project planning packages (Phase A–C) | [project-design-skill](https://github.com/alfred-intelligence/project-design-skill) |

## Publicera en ny skill

Hela publish-flödet i tre kommandon:

```bash
# 1. Scaffolda ett nytt skill-repo lokalt
./scripts/create-skill.sh min-skill "Kort beskrivning av vad skillet gör"

# 2. Pusha till GitHub (skapar repo i alfred-intelligence-orgen)
cd ../min-skill
gh repo create alfred-intelligence/min-skill --public --source=. --push

# 3. Lägg till entry i marketplace.json och pusha
# (redigera .claude-plugin/marketplace.json, lägg till en plugin-entry, commit + push)
```

Skillet är direkt installerbart för alla som har marketplacen tillagd:

```
/plugin install min-skill@alfred
```

## Plugin-struktur

Varje plugin-repo ska ha:

```
<repo>/
├── .claude-plugin/
│   └── plugin.json          # name, description, author
├── skills/
│   └── <name>/
│       ├── SKILL.md         # frontmatter (name, description) + instruktioner
│       └── references/      # ev. helper-filer
├── commands/                # ev. slash-commands (*.md)
├── agents/                  # ev. subagents (*.md)
└── README.md
```

Minimumkravet är `.claude-plugin/plugin.json` + minst ett av `skills/`, `commands/` eller `agents/`.

## SKILL.md frontmatter

```yaml
---
name: kostnadsrakning
description: En mening om vad det gör + när det ska triggas. Var specifik — Claude använder description för att avgöra om skillet är relevant.
---

# Skill-titel

Instruktioner till Claude här.
```

## Lägg till en plugin i marketplacen

Redigera `.claude-plugin/marketplace.json`:

```json
{
  "name": "min-skill",
  "description": "...",
  "category": "...",
  "source": {
    "source": "github",
    "repo": "alfred-intelligence/min-skill"
  }
}
```

Sedan `git push`. Nästa gång någon kör `/plugin marketplace update alfred` blir den nya pluginen tillgänglig.
