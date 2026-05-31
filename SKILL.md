---
name: poc-hello
description: Thin-shell POC skill (tickle 0196). Carries no instructions of its own — it fetches its real instructions at runtime from the tickle MCP get_skill tool, proving server-side skill delegation. Invoke with /poc-hello.
---

# POC thin shell — delegates to the tickle server

This skill is a **thin shell**. It deliberately contains no instructions of its
own. Its entire job is to fetch its real instructions from the tickle server,
proving the Option-A delegation model in ticket 0196.

Do this:

1. Call the MCP tool `mcp__tickle__get_skill` with `project="tickle"` and
   `name="hello"`.
2. If it returns a `skill` object, follow the instructions in `skill.body`
   exactly — those are the server-owned instructions.
3. If it returns `skill: null` (or the tool is unavailable), report that the
   server-side skill could not be fetched, and stop.

Do not improvise instructions locally — the point of this skill is that the
behavior lives on the server, not in this file.
