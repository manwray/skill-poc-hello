# tickle-skills

The installer for **tickle's server-owned thin-shell skills** (tickle ticket 0196).

Each tickle skill's *behavior* lives on the tickle server (embedded builtins) and is
fetched at runtime via the tickle MCP `get_skill` tool. On disk, a skill is a tiny
**thin shell** that just calls `get_skill`; an agent is a thin file whose frontmatter is
local (the harness needs it at spawn) but whose body is fetched via `get_agent`. This
repo wires the tickle MCP and stamps those shells into a project — so skills update
centrally with zero re-distribution.

## Install

Agent-facing, step-by-step instructions: **[INSTALL.md](INSTALL.md)** (fetch the raw URL,
not the GitHub HTML page).

The short version, once the tickle MCP is configured + loaded:

```sh
git clone https://github.com/manwray/tickle-skills.git ~/code/tickle-skills
cd /path/to/your/project

# whole set (recommended): ask the MCP `list_skills`, pass the builtin names —
# install-all.sh stamps each skill shell + only the agents those skills spawn
~/code/tickle-skills/install-all.sh attention audit blast build conform decompose discuss flesh groom intake order research size

# or granular:
~/code/tickle-skills/install-skill.sh blast order
~/code/tickle-skills/install-agent.sh ticket-flesher
```

## Scripts

- `install-all.sh <skill>...` — one-shot: stamp the named skill shells + their agent deps
  (knows the skill→agent map). The set is discovered via `list_skills`, not hardcoded.
- `install-skill.sh <skill>...` — stamp thin skill shells from `SKILL.template.md`.
- `install-agent.sh <agent>...` — stamp thin agent files from `AGENT.template.md`.
- `add-tickle-mcp.sh [scope]` — wire the tickle MCP (the **user** runs this; it prompts
  for a personal `tk_…` token).

The generated shells/agents are git-excluded (`.git/info/exclude`) so they stay out of
the consuming project's history.

## Recommended CLAUDE.md snippet — parallel sessions

The skills carry tickle's parallel-work convention (tickle 0373): **agent work never
mutates the shared checkout's branch state**. The skill bodies enforce it themselves,
but human contributors and non-tickle agents don't read skill bodies — paste this into
the consuming project's `CLAUDE.md` (or conventions doc) so every session follows the
same rule:

```markdown
## Parallel sessions / collision-free git
Multiple agent sessions may run concurrently in this repo:
- Never stash or branch-switch the shared checkout — no `git stash`, no
  `git checkout <branch>` in a checkout someone else may be using.
- Single-commit-on-main work: proceed only when the tree is clean AND on main;
  otherwise abort and say so (or do the work in a dedicated worktree on a temp
  branch and `git push origin HEAD:main`).
- Branch-scoped work: use a dedicated git worktree (`git worktree add`) — a
  branch is exclusive to one worktree.
- Stage explicit files; never `git add -A`.
```

## Teardown

See the Teardown section in [INSTALL.md](INSTALL.md).
