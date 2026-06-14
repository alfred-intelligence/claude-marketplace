#!/usr/bin/env bash
set -euo pipefail

# create-skill.sh — scaffold a new Claude Code skill repo
#
# Usage:
#   ./scripts/create-skill.sh <name> "<description>" [parent-dir]
#
# Creates ../<name>/ (or [parent-dir]/<name>/) with a complete plugin layout:
#   .claude-plugin/plugin.json
#   skills/<name>/SKILL.md
#   README.md
#   .gitignore
#
# After scaffolding:
#   cd ../<name>
#   git init && git add . && git commit -m "feat: initial skill"
#   gh repo create alfred-intelligence/<name> --public --source=. --push

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <name> \"<description>\" [parent-dir]" >&2
  echo "" >&2
  echo "Example:" >&2
  echo "  $0 my-skill \"Does X when user mentions Y or Z\"" >&2
  exit 1
fi

NAME="$1"
DESCRIPTION="$2"
PARENT_DIR="${3:-$(dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)")/..}"
PARENT_DIR="$(cd "$PARENT_DIR" && pwd)"
TARGET="$PARENT_DIR/$NAME"

if ! [[ "$NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then
  echo "Error: name must be lowercase letters, digits, and hyphens, starting with a letter." >&2
  exit 1
fi

if [[ -e "$TARGET" ]]; then
  echo "Error: $TARGET already exists." >&2
  exit 1
fi

AUTHOR_NAME="${SKILL_AUTHOR_NAME:-Mr.RedHat}"
AUTHOR_EMAIL="${SKILL_AUTHOR_EMAIL:-mrredhat317@gmail.com}"
AUTHOR_URL="${SKILL_AUTHOR_URL:-https://github.com/mr-redhat-fb}"
ORG="${SKILL_ORG:-alfred-intelligence}"
MARKETPLACE="${SKILL_MARKETPLACE:-alfred}"

mkdir -p "$TARGET/.claude-plugin" "$TARGET/skills/$NAME"

cat > "$TARGET/.claude-plugin/plugin.json" <<EOF
{
  "\$schema": "https://anthropic.com/claude-code/plugin.schema.json",
  "name": "$NAME",
  "version": "0.1.0",
  "description": "$DESCRIPTION",
  "author": {
    "name": "$AUTHOR_NAME",
    "email": "$AUTHOR_EMAIL",
    "url": "$AUTHOR_URL"
  }
}
EOF

cat > "$TARGET/skills/$NAME/SKILL.md" <<EOF
---
name: $NAME
description: $DESCRIPTION
---

# $NAME

Beskriv här vad skillet gör och hur Claude ska använda det.

## När detta skill triggas

Lista konkreta formuleringar som ska aktivera skillet:

- "..."
- "..."

## Instruktioner

Beskriv steg-för-steg vad Claude ska göra när skillet är aktivt.
EOF

cat > "$TARGET/README.md" <<EOF
# $NAME

$DESCRIPTION

## Install

\`\`\`
/plugin marketplace add $ORG/claude-marketplace
/plugin install $NAME@$MARKETPLACE
\`\`\`

Se [SKILL.md](skills/$NAME/SKILL.md) för fullständiga instruktioner.
EOF

cat > "$TARGET/.gitignore" <<'EOF'
.DS_Store
*.swp
*.swo
__pycache__/
*.pyc
EOF

echo "Created $TARGET"
echo ""
echo "Next steps:"
echo "  cd $TARGET"
echo "  # Edit skills/$NAME/SKILL.md to fill in the skill instructions"
echo "  git init && git add . && git commit -m 'feat: initial skill'"
echo "  gh repo create $ORG/$NAME --public --source=. --push"
echo ""
echo "Then add this entry to ../claude-marketplace/.claude-plugin/marketplace.json:"
echo ""
cat <<EOF
    {
      "name": "$NAME",
      "description": "$DESCRIPTION",
      "source": {
        "source": "github",
        "repo": "$ORG/$NAME"
      }
    }
EOF
