#!/usr/bin/env bash
#
# install-skill.sh — materialize tickle thin-shell skills into THIS project.
#
# For each NAME, writes .claude/skills/NAME/SKILL.md from SKILL.template.md — a thin
# shell whose only job is to call the tickle MCP get_skill(project="tickle",
# name="NAME") and follow the server-owned body. The real behavior lives on the
# server; these shells are disposable, regenerable artifacts.
#
# Run it from your PROJECT ROOT (the shells land in ./.claude/skills/). The script
# itself can live anywhere — it finds its template relative to its own location.
#
# Usage:
#   cd /path/to/your/project
#   /path/to/tickle-skills/install-skill.sh blast order
#
# Discover available server skills first by asking the tickle MCP `list_skills`
# (server-owned builtins are listed). Then install the ones you want.
#
# Prereq for the skills to actually DO anything at runtime: the tickle MCP must be
# configured + loaded — see add-tickle-mcp.sh and INSTALL.md. (You can generate the
# shells before the MCP is wired; they just won't resolve until it is.)
#
# Safe to run repeatedly — it overwrites each shell from the current template.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$SCRIPT_DIR/SKILL.template.md"

if [ "$#" -eq 0 ]; then
  echo "usage: install-skill.sh <skill-name> [<skill-name> ...]" >&2
  echo "(ask the tickle MCP 'list_skills' to see available server skills)" >&2
  exit 1
fi
if [ ! -f "$TEMPLATE" ]; then
  echo "template not found next to the script: $TEMPLATE" >&2
  exit 1
fi

# git repo root, for the optional zero-footprint ignore line (best-effort).
GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"

for name in "$@"; do
  case "$name" in
    ""|*[!a-z0-9-]*)
      echo "skipping invalid skill name '$name' (lowercase letters, digits, hyphens only)" >&2
      continue ;;
  esac

  dir=".claude/skills/$name"
  mkdir -p "$dir"
  sed "s/{{SKILL}}/$name/g" "$TEMPLATE" > "$dir/SKILL.md"
  echo "✓ installed /$name  ->  $dir/SKILL.md"

  # Keep the generated shell out of the project's git history (best-effort).
  if [ -n "$GIT_ROOT" ]; then
    exclude="$GIT_ROOT/.git/info/exclude"
    line=".claude/skills/$name/"
    if [ -f "$exclude" ] && ! grep -qxF "$line" "$exclude" 2>/dev/null; then
      printf '%s\n' "$line" >> "$exclude"
    fi
  fi
done

echo
echo "Done. A skill added under an already-watched .claude/skills/ root is discovered"
echo "live; if .claude/skills/ is brand-new this session, restart Claude Code."
echo "The shells only resolve once the tickle MCP is configured + loaded (INSTALL.md)."
