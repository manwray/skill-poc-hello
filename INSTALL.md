# Install `poc-hello` (agent instructions)

You are an agent installing the **`poc-hello`** Claude Code skill into the current
project. It is a *thin-shell* skill: running `/poc-hello` makes it fetch its real
instructions at runtime from the **tickle MCP** `get_skill` tool and follow them.
This proves the server-side skill-delegation model (tickle ticket 0196).

Follow these steps exactly. Do not invent behavior; verify each step.

## 1. Prerequisite — the tickle MCP must be reachable

The skill calls the MCP tool `mcp__tickle__get_skill`. Confirm the **tickle** MCP
server is connected in this session and exposes `get_skill` (run `claude mcp list`
— tickle should show `✓ Connected`).

- If it is connected but you don't see `get_skill`, the session likely predates the
  tool's deploy — tell the user to reconnect the tickle MCP (`/mcp` → reconnect) or
  restart the session.
- If tickle is **not** configured at all, add it. It is an HTTP MCP server at
  `https://tickle.onrender.com/mcp` and requires the user's **personal** `Bearer`
  token (their tickle MCP token, format `tk_…`).

  **Where the user gets the token** — it is minted in the tickle web app, not from
  GitHub:

  1. Open the tickle web app: <https://tickle.onrender.com> (sign in if prompted).
  2. Click the **⚙ gear** icon in the top bar to open **Settings**.
  3. Under the **Account** section, find **MCP token** and click
     **Mint MCP token** (the button reads **Re-mint token** if one already exists).
  4. The token is **shown once** — copy it immediately. You can re-mint anytime if
     it's lost; minting issues an *additional* token (it does not revoke earlier
     ones), so any token you've kept stays valid.

  **Never hardcode someone else's token, and never commit a real token to a repo.**
  Once the user has pasted you their token, run (substituting it for
  `<YOUR_TICKLE_PAT>`):

  ```sh
  claude mcp add --transport http tickle https://tickle.onrender.com/mcp \
    --header "Authorization: Bearer <YOUR_TICKLE_PAT>"
  ```

  Scope notes:
  - Default scope is **local** — private to you in this project. Recommended here.
  - Add `-s user` to make tickle available in **every** project on this machine.
  - Avoid `-s project`: that writes the server into a committed `.mcp.json`, which
    would leak your token to anyone with repo access.

  After adding, restart the session (or `/mcp` → reconnect) so the tools load, then
  re-run `claude mcp list` to confirm `tickle … ✓ Connected`.

## 2. Install the skill

Pick one location. **Project-level** is recommended for "try it on this project":

```sh
# Project-level — only this project. Run from the project root.
git clone https://github.com/manwray/skill-poc-hello.git .claude/skills/poc-hello
```

If this project is a git repo and you want it pinned/versioned (the 0196 model):

```sh
git submodule add https://github.com/manwray/skill-poc-hello.git .claude/skills/poc-hello
```

Or **personal-level** — makes `/poc-hello` available in *every* project on this machine:

```sh
git clone https://github.com/manwray/skill-poc-hello.git ~/.claude/skills/poc-hello
```

The skill's command name is its directory name, so cloning into `.../poc-hello/`
registers **`/poc-hello`**. (HTTPS clone is used so no SSH key is needed — the repo
is public.)

## 3. Make it discoverable

- Claude Code discovers a new skill under an **already-watched** skills root live, no
  restart. But if the project had **no `.claude/skills/` directory before this session**,
  or you installed at the top level of `~/.claude/skills` for the first time, **restart
  Claude Code** so the new root is watched.
- Project-level skills require accepting the **workspace-trust** prompt before they load.

## 4. Verify

1. Confirm `/poc-hello` shows up in the available skills.
2. Run `/poc-hello`. Expected behavior: it calls
   `mcp__tickle__get_skill(project="tickle", name="hello")` and then prints, from the
   **server-returned** body:

   > 👋 Hello — these instructions were served by the tickle MCP get_skill tool
   > (embedded server-side), not by the local SKILL.md.

   If you see that line, delegation works end-to-end: the instructions came from the
   server, not from the local `SKILL.md`.

## Troubleshooting

- **`skill: null` from get_skill** → the server has no `hello` skill, or you're pointed
  at a stale/old MCP session. Reconnect the tickle MCP and retry.
- **`get_skill` tool not found** → tickle MCP not connected, or the session predates the
  tool deploy. Reconnect/restart the MCP.
- **`/poc-hello` not listed** → see step 3 (restart / workspace trust).
- **Precedence** → a personal `~/.claude/skills/poc-hello` overrides a project-level one
  of the same name (enterprise > personal > project).

## Teardown

```sh
# plain clone
rm -rf .claude/skills/poc-hello        # or ~/.claude/skills/poc-hello

# submodule
git submodule deinit -f .claude/skills/poc-hello
git rm -f .claude/skills/poc-hello
```

To also remove the tickle MCP server (if you added it just for this test):

```sh
claude mcp remove "tickle" -s local    # match the scope you added it with
```
