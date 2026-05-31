# Install `poc-hello` (agent instructions)

You are an agent installing the **`poc-hello`** Claude Code skill into the current
project. It is a *thin-shell* skill: running `/poc-hello` makes it fetch its real
instructions at runtime from the **tickle MCP** `get_skill` tool and follow them.
This proves the server-side skill-delegation model (tickle ticket 0196).

Follow these steps exactly. Do not invent behavior; verify each step.

> **Who does what.** Steps are labelled **(agent)** or **(user)**. You, the agent, do
> the on-disk work (steps 1–2). The **user** must do the things you cannot: paste a
> secret token, restart Claude Code, click trust prompts (step 3–4). Step 5 is yours.
> When a step is the user's, do your prep, then **STOP and hand control to the user**
> with clear instructions — don't idle-wait, and don't try to do their part for them.

> **Fetching this file?** Use the raw URL, not the GitHub HTML page:
> `https://raw.githubusercontent.com/manwray/skill-poc-hello/main/INSTALL.md`
> (the `/blob/` page is ~250 KB of HTML chrome; raw is the ~4 KB doc).

> **Heads-up — this may be a two-phase install.** If the tickle MCP is **not already
> connected with its tools loaded**, you cannot finish in one session: adding an MCP
> server requires a **full Claude Code restart** before its tools become callable. The
> steps are ordered so the on-disk work happens first, then the user restarts **once**
> (by resuming, step 4), then you verify. A restart in the middle is expected — not a
> failure.

## 1. Check the prerequisite (agent)

The skill calls the MCP tool `mcp__tickle__get_skill`. You must confirm that tool is
**actually callable in this session** — which is *not* the same as the server showing
"connected". Determine it like this, in order:

1. **Is `mcp__tickle__get_skill` in your available tools right now?** Look at your own
   tool list (some harnesses surface MCP tools lazily — search/list your tools for the
   name). If you can see it, it's loaded → tickle is fully wired. **Skip to step 2,
   then step 5.**
2. If it is **not** in your tool list, run `claude mcp list`:
   - **tickle shown `✓ Connected`** → the server is configured but its tools aren't
     loaded into *this* session (common when the session started before tickle was
     added). You do **not** re-add it; it just needs a restart (step 4). Do step 2, then
     hand off for the restart.
   - **tickle not listed at all** → it isn't configured. Do step 2, then step 3 to add
     it, then the restart.

> **Two traps to avoid:** (a) A `✓ Connected` line is **not** proof the tool is loaded
> — only your tool list is. (b) Do **not** "probe" by calling `get_skill` and reading a
> failure as "the skill is broken." A missing/erroring tool here means *not loaded →
> restart*, **not** the `skill: null` case (that one is a *successful* call that
> returns null — see troubleshooting). Don't confuse the two branches.

## 2. Install the skill — project-level (agent)

Do this now, regardless of the MCP state — it has no dependency on the MCP, and it puts
the helper script (needed in step 3) on disk. **Install it in *this* project, from the
project root:**

```sh
git clone https://github.com/manwray/skill-poc-hello.git .claude/skills/poc-hello
```

The skill's command name is its directory name, so cloning into `.../poc-hello/`
registers **`/poc-hello`**. (HTTPS clone needs no SSH key — the repo is public.)

> **"Won't this pollute the project repo?" — No, and do not escape to personal-level
> over this.** A `git clone` into `.claude/skills/poc-hello` is a *nested* git repo (it
> has its own `.git`). Git treats it as a single **untracked** path and will not commit
> its contents into the project. Even if the project tracks `.claude/skills/` (many
> do), the POC stays out of the project's history.
>
> For a **guaranteed zero footprint** (never shows in `git status`; a stray `git add
> -A` can't embed it), add one local, uncommitted ignore line:
>
> ```sh
> echo ".claude/skills/poc-hello/" >> .git/info/exclude
> ```
>
> Do **not** install to `~/.claude/skills/` to "avoid pollution." That makes
> `/poc-hello` appear in **every** project and **overrides** any project-level copy
> (enterprise > personal > project) — the opposite of a clean per-project trial. Use
> personal-level only if you genuinely want this skill everywhere (variant below).

**Variants (only if you specifically want them):**

- **Pinned / version-tracked in this project** (intentionally committed, the 0196
  model) — a submodule instead of a plain clone:
  `git submodule add https://github.com/manwray/skill-poc-hello.git .claude/skills/poc-hello`
- **Every project on this machine** (deliberate, not a fallback) — clone to
  `~/.claude/skills/poc-hello` instead.

> Project-level skills require accepting a **workspace-trust** prompt. That prompt is
> the **user's** click — you cannot accept it for them; mention it when you hand off.

**If step 1 found `get_skill` already callable, you are done with setup — go to step 5.**
Otherwise continue to step 3.

## 3. Add the tickle MCP server — only if it's missing (user runs it)

tickle is an HTTP MCP server at `https://tickle.onrender.com/mcp` that needs the user's
**personal** MCP token (`tk_…`). The helper script you just cloned reads the token from
a silent prompt (never shell history, never your context) and prints the mint steps
itself.

> **You (the agent) cannot run this script and must NOT.** It prompts via `read -s`,
> which needs a real interactive terminal. The Claude Code `!` prefix and your Bash
> tool are **not** TTYs — `read -s` will hang or read nothing. Do **not** run it via
> `!` and do **not** run it with your Bash tool. **Hand off: tell the user to run it in
> their own terminal:**

```sh
# The USER runs this in their own terminal, from the project root:
./.claude/skills/poc-hello/add-tickle-mcp.sh          # local scope (default)
./.claude/skills/poc-hello/add-tickle-mcp.sh user     # user scope — every project
```

The script refuses `project` scope on purpose (that would commit the token into a
shared `.mcp.json`).

**If the script can't be used**, the user can run the equivalent manually — but the
token lands in their shell history this way, so the script is preferred:

```sh
claude mcp add --transport http tickle https://tickle.onrender.com/mcp \
  --scope local \
  --header "Authorization: Bearer <THE_USERS_TOKEN>"
```

**Never hardcode someone else's token, and never commit a real token to a repo.**

## 4. Restart by resuming, so the flow survives (user restarts; you prep)

A restart is what loads the new MCP tools, but a plain restart also **wipes this
conversation**. Bridge it by **resuming**: a fresh `claude` process reconnects all
configured MCP servers from config (loading `get_skill`) *and* `--continue` restores
this conversation, so you pick up at step 5 automatically. (Confirmed against the Claude
Code docs: resume = new process = fresh MCP init + full context restore.)

**Before you hand off for the restart, do both:**

1. **Drop a resume marker** as the last line of your turn — this is the *primary*
   continuity mechanism (the resumed you re-reads the transcript and obeys it):

   > ⏸ RESUME MARKER: tickle MCP added; skill cloned. After you relaunch, I will
   > re-check that `get_skill` is callable and then run `/poc-hello` to verify.

2. **Write a fallback breadcrumb** — only used if the user starts a *fresh* session
   instead of resuming. Point it at wherever you installed the skill (project path
   shown):

   ```sh
   echo "poc-hello install: MCP added; next = re-check get_skill, then /poc-hello" \
     > .claude/skills/poc-hello/.install-state
   ```

**Then hand off — tell the user to fully quit Claude Code and relaunch by resuming:**

```sh
claude --continue        # auto-resumes the most recent session in this directory
# or: claude --resume    # picker, if they want to choose the session
```

> **A real restart, not just `/mcp` → reconnect.** Reconnect refreshes the connection
> but is not confirmed to load tool *schemas* for a mid-session add — exactly the gotcha
> these docs exist to prevent. Quitting and relaunching with `claude --continue` always
> works and keeps the conversation.

## 5. Verify (agent, after resume)

**First re-run the step-1 callability check.** Is `mcp__tickle__get_skill` now in your
tool list? If **not**, do not proceed — the restart didn't take; tell the user to fully
quit and relaunch again (a `/mcp` reconnect is not enough). Only once it's callable:

Run `/poc-hello`. It calls `mcp__tickle__get_skill(project="tickle", name="hello")` and
prints, from the **server-returned** body:

> 👋 Hello — these instructions were served by the tickle MCP get_skill tool
> (embedded server-side), not by the local SKILL.md.

This is a valid proof because the thin-shell `SKILL.md` **does not contain that text** —
it only contains instructions to *call* `get_skill`. So seeing the line means the body
came from the server. Confirm you actually invoked `get_skill` (the tool call is in your
turn); if `/poc-hello` printed anything without that call, treat it as a failure, not a
pass.

On success, clean up the fallback breadcrumb if you wrote one:
`rm -f .claude/skills/poc-hello/.install-state`.

## Troubleshooting

- **`get_skill` not in your tool list though `claude mcp list` says `✓ Connected`** →
  tools aren't loaded into this session. **Fully restart Claude Code (resume with
  `claude --continue`)** — do not rely on `/mcp` → reconnect. This is the #1 gotcha
  (steps 1, 4, 5).
- **`skill: null` returned from a *successful* get_skill call** → the server has no
  `hello` skill, or you're on a stale/old MCP session. Reconnect the tickle MCP and
  retry. (Different from the tool being absent — that's the restart case above.)
- **`/poc-hello` not listed** → restart (step 4) and have the user accept the
  workspace-trust prompt.
- **`/poc-hello` runs but seems stale / wrong** → a personal `~/.claude/skills/poc-hello`
  shadows the project copy (enterprise > personal > project). Remove the personal one if
  you didn't intend it.

## Teardown

```sh
# plain clone
rm -rf .claude/skills/poc-hello        # or ~/.claude/skills/poc-hello

# submodule
git submodule deinit -f .claude/skills/poc-hello
git rm -f .claude/skills/poc-hello
```

If you added the local ignore line in step 2, drop it too (edit `.git/info/exclude` and
remove the `.claude/skills/poc-hello/` line).

To also remove the tickle MCP server (if you added it just for this test) — **match the
scope it was added with** (`local` is the script's default; use `user` if that was
chosen):

```sh
claude mcp remove "tickle" -s local    # or: -s user
```
