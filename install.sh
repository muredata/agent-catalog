#!/usr/bin/env bash
# Installs the agent-catalog skill into one or more coding agents' skills
# directories (Claude Code, Codex, Copilot).
#
#   curl -fsSL https://raw.githubusercontent.com/muredata/agent-catalog/main/install.sh | bash
#
# With no flags, prompts interactively for which agent(s) to install to and
# whether to install at project scope (./<agent>/skills) or global scope
# (~/.<agent>/skills). Pass --agent/--scope to skip the prompts, e.g. for
# scripted installs:
#
#   curl -fsSL .../install.sh | bash -s -- --agent claude,codex --scope global
#
# Per-agent global directories can be overridden with:
#   AGENT_CATALOG_CLAUDE_SKILLS_DIR, AGENT_CATALOG_CODEX_SKILLS_DIR,
#   AGENT_CATALOG_COPILOT_SKILLS_DIR
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/muredata/agent-catalog/main"
SKILL_NAME="agent-catalog"

AGENT_ORDER=(claude codex copilot)
declare -A LABELS=(
  [claude]="Claude Code"
  [codex]="Codex"
  [copilot]="Copilot"
)
declare -A GLOBAL_DIRS=(
  [claude]="${AGENT_CATALOG_CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
  [codex]="${AGENT_CATALOG_CODEX_SKILLS_DIR:-$HOME/.codex/skills}"
  [copilot]="${AGENT_CATALOG_COPILOT_SKILLS_DIR:-$HOME/.copilot/skills}"
)
declare -A PROJECT_DIRS=(
  [claude]=".claude/skills"
  [codex]=".codex/skills"
  [copilot]=".copilot/skills"
)

usage() {
  cat <<EOF
Usage: install.sh [--agent claude|codex|copilot|all[,...]] [--scope project|global]

  --agent   Agent(s) to install the skill for. Comma-separated, or "all".
            Defaults to an interactive prompt.
  --scope   Install location: "project" (./<agent>/skills, relative to the
            current directory) or "global" (~/.<agent>/skills). Defaults to
            an interactive prompt.
EOF
}

agents_csv=""
scope=""

while [ $# -gt 0 ]; do
  case "$1" in
    --agent)
      agents_csv="$2"
      shift 2
      ;;
    --scope)
      scope="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

tty_in() {
  if [ -r /dev/tty ]; then
    echo /dev/tty
  else
    echo ""
  fi
}

prompt_agents() {
  local tty
  tty="$(tty_in)"
  if [ -z "$tty" ]; then
    echo "Error: no --agent given and no terminal available to prompt." >&2
    usage
    exit 1
  fi

  echo "Select coding agent(s) to install the '$SKILL_NAME' skill for:" >&2
  local i=1 a
  for a in "${AGENT_ORDER[@]}"; do
    printf "  %d) %s\n" "$i" "${LABELS[$a]}" >&2
    i=$((i + 1))
  done
  local reply
  printf "Enter numbers separated by spaces (e.g. \"1 3\"), or 'a' for all: " >&2
  read -r reply <"$tty"

  if [ "$reply" = "a" ] || [ "$reply" = "A" ]; then
    printf '%s\n' "${AGENT_ORDER[@]}"
    return
  fi

  local n selected=()
  for n in $reply; do
    case "$n" in
      1) selected+=("claude") ;;
      2) selected+=("codex") ;;
      3) selected+=("copilot") ;;
      *) echo "Ignoring invalid selection: $n" >&2 ;;
    esac
  done
  if [ "${#selected[@]}" -eq 0 ]; then
    echo "Error: no valid agent selected." >&2
    exit 1
  fi
  printf '%s\n' "${selected[@]}"
}

prompt_scope() {
  local tty
  tty="$(tty_in)"
  if [ -z "$tty" ]; then
    echo "Error: no --scope given and no terminal available to prompt." >&2
    usage
    exit 1
  fi

  local reply
  printf "Install scope — [p]roject (./<agent>/skills) or [g]lobal (~/.<agent>/skills)? [p/g]: " >&2
  read -r reply <"$tty"
  case "$reply" in
    g|G|global|Global) echo "global" ;;
    *) echo "project" ;;
  esac
}

# Resolve agents
agents=()
if [ -n "$agents_csv" ]; then
  IFS=',' read -ra requested <<<"$agents_csv"
  for a in "${requested[@]}"; do
    if [ "$a" = "all" ]; then
      agents=("${AGENT_ORDER[@]}")
      break
    fi
    if [ -z "${LABELS[$a]:-}" ]; then
      echo "Error: unknown agent '$a' (expected: claude, codex, copilot, all)" >&2
      exit 1
    fi
    agents+=("$a")
  done
else
  mapfile -t agents < <(prompt_agents)
fi

# Resolve scope
if [ -z "$scope" ]; then
  scope="$(prompt_scope)"
fi
case "$scope" in
  project|global) ;;
  *)
    echo "Error: --scope must be 'project' or 'global' (got '$scope')" >&2
    exit 1
    ;;
esac

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

green=$'\033[32m'
grey=$'\033[90m'
reset=$'\033[0m'

for a in "${agents[@]}"; do
  if [ "$scope" = "global" ]; then
    target_dir="${GLOBAL_DIRS[$a]}/$SKILL_NAME"
  else
    target_dir="${PROJECT_DIRS[$a]}/$SKILL_NAME"
  fi
  mkdir -p "$target_dir"
  fetch "$REPO_RAW/skills/$SKILL_NAME/SKILL.md" "$target_dir/SKILL.md"
  printf "%s✓%s Installed %s skill for %s to %s\n" "$green" "$reset" "$SKILL_NAME" "${LABELS[$a]}" "$target_dir"
done

printf "%s  Invoke it as: /%s <query>%s\n" "$grey" "$SKILL_NAME" "$reset"
