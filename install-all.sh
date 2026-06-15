#!/usr/bin/env bash
#
# install-all.sh — one-shot onboarding: stamp a batch of tickle skill shells AND the
# agents those skills depend on, into THIS project (tickle ticket 0196, child C6).
#
# The tickle skill SET is server-owned and discoverable — it is NOT hardcoded here.
# The installing agent asks the tickle MCP `list_skills`, takes the builtin skill
# names, and passes them in:
#
#   cd /path/to/your/project
#   /path/to/tickle-skills/install-all.sh attention audit blast build conform decompose discuss flesh groom intake research size
#
# This script then:
#   1. stamps a thin shell per skill (delegates to install-skill.sh), and
#   2. installs ONLY the agents those skills actually spawn (skill->agent map below),
#      via install-agent.sh — so installing a subset pulls just its agent deps.
#
# Agents carry no behavior of their own either; like the skills they fetch their real
# instructions at spawn via the tickle MCP get_agent tool. The map below is the one
# place the (small, slow-changing) skill->agent dependency is recorded.
#
# Prereq for anything to RESOLVE at runtime: the tickle MCP must be configured + loaded
# (see add-tickle-mcp.sh and INSTALL.md). The shells/agents can be stamped before that;
# they just won't resolve until the MCP is wired. Safe to run repeatedly.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$#" -eq 0 ]; then
  echo "usage: install-all.sh <skill-name> [<skill-name> ...]" >&2
  echo "(ask the tickle MCP 'list_skills' for the available server skills, then pass them here)" >&2
  exit 1
fi

# skill -> agent it spawns. Skills not listed here need no agent. Keep in sync with the
# server's agent set (get_agent): currently ticket-flesher, size-scanner,
# ticket-researcher, conform-lens.
agent_for() {
  case "$1" in
    flesh|intake)    echo ticket-flesher ;;
    size)            echo size-scanner ;;
    groom|research)  echo ticket-researcher ;;
    conform)         echo conform-lens ;;
    *)               echo "" ;;
  esac
}

# 1. Stamp the skill shells (install-skill.sh validates names + handles git-exclude).
"$SCRIPT_DIR/install-skill.sh" "$@"

# 2. Collect the agent deps for the requested skills (deduped).
agents=""
for s in "$@"; do
  a="$(agent_for "$s")"
  [ -z "$a" ] && continue
  case " $agents " in
    *" $a "*) ;;            # already collected
    *) agents="$agents $a" ;;
  esac
done

echo
if [ -n "$agents" ]; then
  # shellcheck disable=SC2086 — word-splitting is intentional (list of agent names).
  "$SCRIPT_DIR/install-agent.sh" $agents
else
  echo "No agent-backed skills in this set — no agents to install."
fi

echo
echo "Done. Installed $# skill shell(s)${agents:+ + agents:$agents}."
echo "They resolve once the tickle MCP is configured + loaded (INSTALL.md). If"
echo ".claude/skills or .claude/agents was brand-new this session, restart Claude Code."
