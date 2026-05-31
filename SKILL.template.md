---
name: {{SKILL}}
description: Thin-shell tickle skill (0196). Carries no instructions of its own — it fetches its real instructions at runtime from the tickle MCP get_skill tool (server-owned skill "{{SKILL}}"). Invoke with /{{SKILL}}.
---

# Thin shell — delegates to the tickle server (skill: {{SKILL}})

This skill is a **thin shell**. It deliberately contains no instructions of its own.
Its entire job is to fetch its real instructions from the tickle server, proving the
server-side delegation model in ticket 0196.

Do this:

1. Call the MCP tool `mcp__tickle__get_skill` with `project="tickle"` and
   `name="{{SKILL}}"`.
2. If it returns a `skill` object, follow the instructions in `skill.body` exactly —
   those are the server-owned instructions.
3. If it returns `skill: null` (or the tool is unavailable), report that the
   server-side skill could not be fetched, and stop. (If the tool is *unavailable*
   rather than null, the tickle MCP likely needs a restart — see the repo's INSTALL.md.)

Do not improvise instructions locally — the point of this skill is that the behavior
lives on the server, not in this file.
