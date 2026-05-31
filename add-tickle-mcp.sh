#!/usr/bin/env bash
#
# add-tickle-mcp.sh — register the tickle MCP server in Claude Code WITHOUT the
# bearer token landing in your shell history.
#
# The token is read silently (read -s) from an interactive prompt, so it is never
# typed on the command line and therefore never written to ~/.zsh_history,
# ~/.bash_history, or your terminal scrollback.
#
# Usage:
#   ./add-tickle-mcp.sh           # local scope — private to this project (default)
#   ./add-tickle-mcp.sh user      # user scope  — every project on this machine
#
# Mint a token first (it is shown once):
#   https://tickle.onrender.com  →  ⚙ Settings  →  Account  →  Mint MCP token
#
# Residual caveat: the token is passed to `claude mcp add` as a process argument,
# so it is briefly visible in `ps` to other users on a shared machine. That is a
# limitation of the CLI, not this script; on a single-user laptop it is moot.

set -euo pipefail

SCOPE="${1:-local}"
URL="https://tickle.onrender.com/mcp"

case "$SCOPE" in
  local|user) ;;
  project)
    echo "Refusing scope 'project': it writes the token into a committed .mcp.json," >&2
    echo "which would leak it to anyone with repo access. Use 'local' (default) or 'user'." >&2
    exit 1 ;;
  *)
    echo "Unknown scope '$SCOPE'. Use 'local' (default) or 'user'." >&2
    exit 1 ;;
esac

if ! command -v claude >/dev/null 2>&1; then
  echo "The 'claude' CLI was not found on PATH. Install/launch Claude Code first." >&2
  exit 1
fi

# Tell the user where to get the token, right here, so no agent has to relay it.
cat >&2 <<'MINT'

  Need a tickle MCP token? Mint one in the web app (it is shown once):

    1. Open  https://tickle.onrender.com   (sign in if prompted)
    2. Top-bar gear icon  ->  Settings
    3. Under  Account > MCP token ,  click  "Mint MCP token"
         (the button reads "Re-mint token" if you already have one)
    4. Copy the  tk_...  value it shows.

  Re-minting issues an ADDITIONAL token; it does not revoke earlier ones.
  ---------------------------------------------------------------------------

MINT

# Read the token silently: not echoed to the screen, not stored in shell history.
printf 'Paste your tickle MCP token (tk_…), then press Enter: ' >&2
read -rs TOKEN
printf '\n' >&2

if [ -z "${TOKEN}" ]; then
  echo "No token entered. Aborting." >&2
  exit 1
fi
case "$TOKEN" in
  tk_*) ;;
  *) echo "Warning: token does not start with 'tk_'. Continuing anyway." >&2 ;;
esac

claude mcp add --transport http tickle "$URL" \
  --scope "$SCOPE" \
  --header "Authorization: Bearer ${TOKEN}"

unset TOKEN

echo
echo "✓ Added the tickle MCP server (scope: $SCOPE)."
echo "IMPORTANT: a 'Connected' status is not enough. Fully QUIT AND RELAUNCH Claude"
echo "Code so the get_skill tool loads into your session. Do NOT rely on '/mcp' →"
echo "reconnect alone — for a server added mid-session it may not load the tools."
