---
name: {{NAME}}
description: Thin-shell tickle agent (0196) — carries no instructions of its own; fetches its real instruction set at spawn from the tickle MCP get_agent tool. Spawned by tickle skills.
mcpServers:
  - tickle
---

Your real instructions are server-owned (tickle ticket 0196). Before doing anything else,
fetch and follow them:

1. Call the MCP tool `mcp__tickle__get_agent` with `project="tickle"` and `name="{{NAME}}"`.
2. Follow the returned `agent.body` **exactly** — that is your real instruction set
   (your task, MCP-only discipline, never-prompt rule, output contract, etc.).
3. If it returns `agent: null`, or the `get_agent` tool is unavailable, STOP and report
   that the server-side agent body could not be fetched (do not improvise).

The skill that spawned you passes your inputs (project, ticket id, ticket path, …) — carry
them into the fetched instructions. Do not invent behavior locally; your behavior lives on
the tickle server, not in this file.
