#!/usr/bin/env bash
#
# install-agent.sh — materialize tickle thin-shell AGENTS into THIS project.
#
# For each NAME, writes .claude/agents/NAME.md from AGENT.template.md — a thin agent
# whose body fetches its real instructions at spawn via the tickle MCP get_agent tool.
# Only the frontmatter (name + mcpServers: [tickle]) lives locally; the harness needs
# that at spawn-config time. The instruction body is server-owned and updates centrally.
#
# Companion to install-skill.sh (skills). Run from your PROJECT ROOT (agents land in
# ./.claude/agents/). The script finds its template relative to its own location.
#
# Usage:
#   cd /path/to/your/project
#   /path/to/tickle-skills/install-agent.sh ticket-intake size-scanner ticket-researcher
#
# Discover available agents by asking the tickle MCP `get_agent` (or list_skills once
# agents are surfaced there). Prereq for the agents to DO anything: the tickle MCP must
# be configured + loaded — see add-tickle-mcp.sh and INSTALL.md.
#
# Safe to run repeatedly — it overwrites each agent from the current template.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$SCRIPT_DIR/AGENT.template.md"

if [ "$#" -eq 0 ]; then
  echo "usage: install-agent.sh <agent-name> [<agent-name> ...]" >&2
  exit 1
fi
if [ ! -f "$TEMPLATE" ]; then
  echo "template not found next to the script: $TEMPLATE" >&2
  exit 1
fi

GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
mkdir -p .claude/agents

for name in "$@"; do
  case "$name" in
    ""|*[!a-z0-9-]*)
      echo "skipping invalid agent name '$name' (lowercase letters, digits, hyphens only)" >&2
      continue ;;
  esac

  dst=".claude/agents/$name.md"
  sed "s/{{NAME}}/$name/g" "$TEMPLATE" > "$dst"
  echo "✓ installed agent $name  ->  $dst"

  # Keep the generated thin agent out of the project's git history (best-effort).
  if [ -n "$GIT_ROOT" ]; then
    exclude="$GIT_ROOT/.git/info/exclude"
    line=".claude/agents/$name.md"
    if [ -f "$exclude" ] && ! grep -qxF "$line" "$exclude" 2>/dev/null; then
      printf '%s\n' "$line" >> "$exclude"
    fi
  fi
done

echo
echo "Done. Agents are discovered when Claude Code (re)scans .claude/agents; if the dir"
echo "was brand-new this session, restart. They only resolve once the tickle MCP is loaded."
