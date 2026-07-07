#!/usr/bin/env bash
# Installs the agent-catalog skill into a Claude Code skills directory.
#
#   curl -fsSL https://raw.githubusercontent.com/muredata/agent-catalog/main/install.sh | bash
#
# Installs to .claude/skills/ if run from inside a project that already has a
# .claude/ directory, otherwise to the personal ~/.claude/skills/. Override
# with AGENT_CATALOG_SKILLS_DIR to force a specific location.
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/muredata/agent-catalog/main"
SKILL_NAME="agent-catalog"

if [ -n "${AGENT_CATALOG_SKILLS_DIR:-}" ]; then
  skills_dir="$AGENT_CATALOG_SKILLS_DIR"
elif [ -d ".claude" ]; then
  skills_dir=".claude/skills"
else
  skills_dir="$HOME/.claude/skills"
fi

target_dir="$skills_dir/$SKILL_NAME"
mkdir -p "$target_dir"

fetch() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$1" -o "$2"
  elif command -v wget >/dev/null 2>&1; then
    wget -q "$1" -O "$2"
  else
    echo "Error: need curl or wget to install." >&2
    exit 1
  fi
}

fetch "$REPO_RAW/skills/$SKILL_NAME/SKILL.md" "$target_dir/SKILL.md"

green=$'\033[32m'
grey=$'\033[90m'
reset=$'\033[0m'

printf "%s✓%s Installed %s skill to %s\n" "$green" "$reset" "$SKILL_NAME" "$target_dir"
printf "%s  Invoke it in Claude Code as: /%s <query>%s\n" "$grey" "$SKILL_NAME" "$reset"