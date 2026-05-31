---
name: poc-hello
description: Proof-of-concept skill for the atomic git-distributed skills model (tickle 0196). Prints a marker so we can confirm a skill distributed as its own git repo — pulled into a skills root as a submodule — was discovered and run by Claude Code. Invoke with /poc-hello.
---

# POC: git-distributed atomic skill

This skill exists only to prove the distribution model in tickle ticket 0196:
a skill that lives in **its own git repo** (`manwray/skill-poc-hello`), pulled
into a skills root (`~/.claude/skills`) as a **top-level git submodule**, and
discovered + invoked by Claude Code with no plugin and no conflict.

## When invoked

1. Print this exact marker line so the user can confirm it ran:

   `✅ poc-hello ran — distributed via git submodule from manwray/skill-poc-hello`

2. Then report, in one line each:
   - the absolute path this `SKILL.md` was loaded from (use `${CLAUDE_SKILL_DIR}`)
   - the current project / working directory, to confirm a personal-root skill is
     available inside *this* project (e.g. tickle) — proving cross-project sharing.

3. Stop. This skill does nothing else.
