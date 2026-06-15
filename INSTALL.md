# Install tickle skills (agent instructions)

This repo (**`tickle-skills`**) is the installer for tickle's **server-owned thin-shell
skills** (tickle ticket 0196). Each skill's *behavior* lives server-side and is fetched
at runtime via the tickle MCP `get_skill` tool; on disk, each skill is a tiny **thin
shell** that just calls `get_skill`. This installer (a) wires the tickle MCP and (b)
stamps out a thin shell per skill with `install-skill.sh`.

Follow these steps exactly. Do not invent behavior; verify each step.

> **Who does what.** Steps are labelled **(agent)** or **(user)**. You, the agent, do
> the on-disk work (clone, generate shells). The **user** must do what you cannot: paste
> a secret token into a terminal, restart Claude Code, accept trust prompts. When a step
> is the user's, do your prep, then **STOP and hand control to the user** — don't
> idle-wait, and don't try to do their part for them.

> **Fetching this file?** Use the raw URL, not the GitHub HTML page:
> `https://raw.githubusercontent.com/manwray/tickle-skills/main/INSTALL.md`

> **Heads-up — this may be a two-phase install.** If the tickle MCP is **not already
> connected with its tools loaded**, you cannot finish in one session: adding an MCP
> server requires a **full Claude Code restart** before its tools become callable. The
> steps are ordered so the on-disk work happens first, then the user restarts **once**
> (by resuming, step 5), then you verify. A restart in the middle is expected.
>
> **Do a real restart — not just `/mcp` → reconnect.** When a server is added
> *mid-session*, reconnect is not confirmed to load the tool *schemas*; fully quit and
> relaunch. Treat reconnect as a shortcut only — if `get_skill` still isn't callable
> after it, restart for real.

## 1. Check the prerequisite (agent)

The thin shells call `mcp__tickle__get_skill`. Confirm that tool is **actually callable
in this session** — which is *not* the same as the server showing "connected":

1. **Is `mcp__tickle__get_skill` in your available tools right now?** Look at your own
   tool list (some harnesses surface MCP tools lazily — search/list your tools for the
   name). If you can see it → tickle is fully wired; you may also call `list_skills` now
   to see which server skills exist. Skip step 4 (the MCP is already there).
2. If it is **not** in your tool list, run `claude mcp list`:
   - **tickle shown `✓ Connected`** → configured but tools aren't loaded into *this*
     session. You do **not** re-add it; it needs a restart (step 5).
   - **tickle not listed at all** → not configured; you'll add it in step 4.

> **Two traps:** (a) `✓ Connected` is **not** proof the tool is loaded — only your tool
> list is. (b) Don't "probe" by calling `get_skill` and reading a failure as "broken": a
> missing/erroring tool means *not loaded → restart*, **not** the `skill: null` case
> (that's a *successful* call returning null — see troubleshooting).

> **Already have a `tickle` MCP?** Some setups run a **local/dev** tickle (e.g. a
> LaunchAgent on `localhost`) under the name `tickle`. These skills target the **hosted**
> server at `https://tickle.onrender.com/mcp`. If a `tickle` is already configured and
> `get_skill` is callable, proceed (any tickle with these builtins works). If
> verification later returns `skill: null`, your `tickle` points at a server lacking the
> builtins → repoint it at the hosted URL.

## 2. Clone the installer (agent)

Clone this repo **outside** the target project (so the project ends up containing only
the generated thin shells, not the installer). Anywhere works; examples use a tools dir:

```sh
git clone https://github.com/manwray/tickle-skills.git ~/code/tickle-skills
```

You now have `add-tickle-mcp.sh`, `install-skill.sh`, and `SKILL.template.md`.

## 3. Install the skill shells (agent)

This is **yours to run** — the install scripts only write files (no token, no TTY), so
run them with your Bash tool from the **project root**. Each writes a thin
`.claude/skills/<name>/SKILL.md` (a shell calling `get_skill` with its own name) and
appends a local `.git/info/exclude` line, so the generated shells stay out of the
project's git history. Skill **command name == directory name == server skill name**.

### 3a. Install the whole tickle set (recommended)

The tickle skill set is **server-owned and discoverable — not hardcoded in the
installer.** If `get_skill` was callable in step 1, ask the MCP what exists and install
it all in one shot:

1. Call `mcp__tickle__list_skills` (project = your project, or `tickle`). It returns the
   server builtins (`source: "builtin"`).
2. Take the skill **names** — typically all of them — and pass them to
   `install-all.sh`:

   ```sh
   cd /path/to/your/project
   ~/code/tickle-skills/install-all.sh attention audit blast build conform decompose discuss flesh groom intake research size
   ```

`install-all.sh` stamps a shell per skill **and** installs only the agents those skills
spawn (it knows the small skill→agent map: `flesh`/`intake`→`ticket-flesher`,
`size`→`size-scanner`, `groom`/`research`→`ticket-researcher`, `conform`→`conform-lens`;
other skills need none). So the list you pass drives both the skills and their agent deps. The agent files are thin too — they fetch their real
instructions at spawn via `get_agent`.

> Cold start (get_skill not callable yet)? You can't discover the set — wait until after
> the restart (step 5) and run 3a then.

### 3b. Install specific skills (granular)

To pick individual skills instead of the whole set:

```sh
~/code/tickle-skills/install-skill.sh blast        # skills only
~/code/tickle-skills/install-agent.sh ticket-flesher     # an agent, if the skill spawns one
```

Use this when you want a subset whose agent deps you'll manage
yourself. `install-all.sh` is just these two composed with the skill→agent map applied.

## 4. Add the tickle MCP server — only if it's missing (user runs it)

Skip if step 1 found `get_skill` callable, or found tickle `✓ Connected` (then it just
needs the restart in step 5). Otherwise the MCP must be added. It needs the user's
**personal** token (`tk_…`); the helper script reads it from a silent prompt and prints
the mint steps itself.

> **You (the agent) cannot run this script and must NOT.** It prompts via `read -s`,
> which needs a real interactive terminal. The Claude Code `!` prefix and your Bash tool
> are **not** TTYs — `read -s` will hang or read nothing. Do **not** run it via `!` or
> your Bash tool. **Hand off: tell the user to run it in their own terminal:**

```sh
# The USER runs this in their own terminal:
~/code/tickle-skills/add-tickle-mcp.sh          # local scope (default)
~/code/tickle-skills/add-tickle-mcp.sh user     # user scope — every project
```

The script refuses `project` scope (that would commit the token into a shared
`.mcp.json`). **Never hardcode someone else's token, or commit a real token.**

## 5. Restart by resuming, so the flow survives (user restarts; you prep)

A restart loads the new MCP tools, but a plain restart also **wipes this conversation**.
Bridge it by **resuming**: a fresh `claude` process reconnects all configured MCP
servers (loading `get_skill`) *and* `--continue` restores this conversation, so you pick
up at step 6 automatically.

**Before handing off, do both:**

1. **Drop a resume marker** as the last line of your turn (primary continuity):

   > ⏸ RESUME MARKER: tickle skills cloned + shells installed; MCP added. After you
   > relaunch, I will re-check `get_skill` is callable, then run the installed skills to
   > verify.

2. **Write a fallback breadcrumb** (only used if the user starts a fresh session):

   ```sh
   echo "tickle-skills install: shells in place, MCP added; next = re-check get_skill, then verify" \
     > .claude/skills/.install-state
   ```

**Then tell the user to fully quit Claude Code and relaunch by resuming:**

```sh
claude --continue        # auto-resumes the most recent session in this directory
# or: claude --resume    # picker
```

## 6. Verify (agent, after resume)

**First re-run the step-1 callability check.** Is `mcp__tickle__get_skill` now in your
tool list? If **not**, the restart didn't take — tell the user to fully quit and relaunch
again (a `/mcp` reconnect is not enough). Only once it's callable:

**Verify by fetching, not by running** (the real skills mutate tickets — don't invoke
them as a smoke test). Call `mcp__tickle__get_skill` directly for two installed names,
e.g. `name="build"` and `name="blast"` (`project` = your project), and confirm each
returns a **non-null `skill` whose body is that skill's full instructions** — two
different names returning two distinct server bodies proves `get_skill` resolves each by
name. The thin-shell `SKILL.md` files contain none of that text, so the bodies must have
come from the server. (`skill: null` → see troubleshooting.)

On success, optionally clean up the breadcrumb (best-effort — it's gitignored and inert,
so don't fight a hook over it):

```sh
rm -f .claude/skills/.install-state 2>/dev/null || : > .claude/skills/.install-state
```

## Troubleshooting

- **`get_skill` not in your tool list though `claude mcp list` says `✓ Connected`** →
  tools aren't loaded into this session. **Fully restart (resume with `claude
  --continue`)** — don't rely on `/mcp` → reconnect. The #1 gotcha (steps 1, 5, 6).
- **`skill: null` from a *successful* get_skill call** → the server lacks that skill, or
  you're on a stale MCP session / a `tickle` pointed at the wrong server. Reconnect and
  retry. (Different from the tool being absent — that's the restart case above.)
- **A freshly stamped skill not listed as a slash command** → if `.claude/skills/` was
  brand-new this session, restart; accept the workspace-trust prompt (the user's click).
- **A skill runs but seems stale/wrong** → a personal `~/.claude/skills/<name>` shadows
  the project copy (precedence: enterprise > personal > project).

## Teardown

```sh
# remove the generated skill shells (whichever you installed), e.g. the full set:
rm -rf $(printf '.claude/skills/%s ' attention audit blast build conform decompose discuss flesh groom intake research size)
# and the thin agent files, if any were installed (install-all / install-agent)
rm -f .claude/agents/ticket-flesher.md .claude/agents/size-scanner.md \
      .claude/agents/ticket-researcher.md .claude/agents/conform-lens.md
# then drop their lines from .git/info/exclude

# remove the tickle MCP (match the scope it was added with)
claude mcp remove "tickle" -s local    # or: -s user

# the installer clone is standalone — delete it wherever you put it
rm -rf ~/code/tickle-skills
```
