# Install `poc-hello` (agent instructions)

You are an agent installing the **`poc-hello`** Claude Code skill into the current
project. It is a *thin-shell* skill: running `/poc-hello` makes it fetch its real
instructions at runtime from the **tickle MCP** `get_skill` tool and follow them.
This proves the server-side skill-delegation model (tickle ticket 0196).

Follow these steps exactly. Do not invent behavior; verify each step.

> **Fetching this file?** Use the raw URL, not the GitHub HTML page:
> `https://raw.githubusercontent.com/manwray/skill-poc-hello/main/INSTALL.md`
> (the `/blob/` page is ~250 KB of HTML chrome; raw is the ~3 KB doc).

> **Heads-up — this may be a two-phase install.** If the tickle MCP is **not already
> connected with its tools loaded**, you cannot finish in one session: adding an MCP
> server requires a **full Claude Code restart** before its tools become callable. The
> steps below are ordered so you do *all* the on-disk work first, then restart **once**,
> then verify. A restart in the middle is expected — it is not a failure.
>
> **Do a real restart — do not just `/mcp` → reconnect.** When a server is added
> *mid-session*, a reconnect refreshes the connection but is **not** confirmed to load
> the tool *schemas* into the running session (the install that prompted these docs
> showed `tickle ✓ Connected` while `get_skill` stayed uncallable). Fully quit and
> relaunch Claude Code. Treat reconnect as a possible shortcut only — if `get_skill`
> still isn't callable after it, restart for real.

## 1. Check the prerequisite

The skill calls the MCP tool `mcp__tickle__get_skill`. There are **two** things to
confirm — connection *and* tools loaded — because they are not the same:

```sh
claude mcp list      # tickle should show `✓ Connected`
```

- **`get_skill` is already callable in this session** → tickle is fully wired. Skip
  to **step 3** (install the skill), then verify.
- **tickle is listed `✓ Connected` but `get_skill` is not callable** → the tools are
  not loaded into this session (common when the session started before tickle was
  added). You do **not** need to re-add it — restart Claude Code (step 4).
- **tickle is not listed at all** → do **step 2** to add it.

> A `✓ Connected` line is **not** the finish line. The session only gains tickle's
> tools after a **full restart** (see step 4); `/mcp` → reconnect is not confirmed to
> load tool schemas for a mid-session add. Don't treat "Connected" as "done."

## 2. Add the tickle MCP server (only if it's missing)

tickle is an HTTP MCP server at `https://tickle.onrender.com/mcp`. It requires the
user's **personal** MCP token (format `tk_…`).

**Where the user gets the token** — it is minted in the tickle web app, not GitHub:

1. Open <https://tickle.onrender.com> (sign in if prompted).
2. Click the **⚙ gear** icon in the top bar to open **Settings**.
3. Under **Account → MCP token**, click **Mint MCP token** (reads **Re-mint token**
   if one already exists).
4. The token is **shown once** — copy it immediately. Re-minting issues an
   *additional* token (it does not revoke earlier ones), so kept tokens stay valid.

**Add the server with the helper script** (recommended) — it reads the token from a
silent prompt so it never lands in shell history or in the agent's context.

> **Agents: you cannot run this script yourself, and you must NOT.** It prompts for the
> user's secret token via `read -s`, which needs a real interactive terminal. The
> Claude Code `!` shell prefix and your Bash tool are **not** TTYs — `read -s` will
> hang or read nothing there. So **do not** run it via `!` and **do not** run it with
> your Bash tool. Instead, tell the **user** to run it in their **own terminal**:

```sh
# The USER runs this in their own terminal, from the cloned skill dir:
./add-tickle-mcp.sh          # local scope — private to this project (default)
./add-tickle-mcp.sh user     # user scope  — every project on this machine
```

The script refuses `project` scope on purpose (that would commit the token into a
shared `.mcp.json`).

**If the script can't be used**, the equivalent manual command is below — but note the
token will be saved in the user's shell history this way, so the script is preferred:

```sh
claude mcp add --transport http tickle https://tickle.onrender.com/mcp \
  --scope local \
  --header "Authorization: Bearer <YOUR_TICKLE_TOKEN>"
```

**Never hardcode someone else's token, and never commit a real token to a repo.**

## 3. Install the skill

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
is public.) Project-level skills require accepting the **workspace-trust** prompt.

## 4. Restart — but resume so the flow survives

Restarting is what loads the new MCP tools, but a plain restart also **wipes this
conversation**, so the agent forgets it was mid-install. Bridge it by **resuming**: a
fresh `claude` process reconnects all configured MCP servers from config (loading
`get_skill`) *and* `--continue` restores this conversation, so the agent picks up at
step 5 automatically. (Confirmed against the Claude Code docs: resume = new process =
fresh MCP init + full context restore.)

**Agent — before telling the user to restart, do these two things:**

1. **Drop a resume marker** as the last line of your turn so the resumed session knows
   exactly what to do next, e.g.:

   > ⏸ RESUME MARKER: tickle MCP added. After you relaunch, I will run `/poc-hello`
   > to verify the server-side delegation.

2. **Write a one-line breadcrumb file** as a fallback in case the user starts a fresh
   session instead of resuming:

   ```sh
   echo "poc-hello install: MCP added $(date -u +%FT%TZ); next step = run /poc-hello to verify" \
     > .claude/skills/poc-hello/.install-state
   ```

**Then tell the user to restart by resuming** (this is the key to a smooth flow):

```sh
# Fully quit Claude Code, then relaunch RESUMING this conversation:
claude --continue        # auto-resumes the most recent session in this directory
# or: claude --resume    # opens a picker if you want to choose the session
```

> **Do a real restart, not just `/mcp` → reconnect.** Reconnect refreshes the
> connection but is not confirmed to load the tool *schemas* for a server added
> mid-session — that is exactly the gotcha these docs exist to prevent. Quitting and
> relaunching with `claude --continue` always works and keeps the conversation.
>
> If `.claude/skills/` already existed **and** tickle's tools were already loaded
> before this session, no restart is needed — a skill added under an already-watched
> root is discovered live. When in doubt, resume-restart: it is cheap and removes both
> failure modes at once.

After relaunching, re-run `claude mcp list` to confirm `tickle … ✓ Connected`, confirm
`/poc-hello` is listed, then go to step 5. (If you resumed, the agent should already be
continuing on its own.)

## 5. Verify

Run `/poc-hello`. Expected behavior: it calls
`mcp__tickle__get_skill(project="tickle", name="hello")` and then prints, from the
**server-returned** body:

> 👋 Hello — these instructions were served by the tickle MCP get_skill tool
> (embedded server-side), not by the local SKILL.md.

If you see that line, delegation works end-to-end: the instructions came from the
server, not from the local `SKILL.md`. Then clean up the install breadcrumb if you
wrote one: `rm -f .claude/skills/poc-hello/.install-state`.

## Troubleshooting

- **`get_skill` not callable though `claude mcp list` says `✓ Connected`** → the tools
  aren't loaded into this session. **Fully restart Claude Code** — do not rely on `/mcp`
  → reconnect, which is not confirmed to load tool schemas for a mid-session add. This
  is the #1 gotcha — see steps 1 and 4.
- **`skill: null` from get_skill** → the server has no `hello` skill, or you're pointed
  at a stale/old MCP session. Reconnect the tickle MCP and retry.
- **`/poc-hello` not listed** → restart (step 4) and accept the workspace-trust prompt.
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
