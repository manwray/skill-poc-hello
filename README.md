# skill-poc-hello

A throwaway **proof-of-concept** Claude Code skill, distributed as its own atomic git repo.

It exists to validate the distribution model described in tickle ticket **0196**
(*Atomic skill distribution: per-skill git repos + personal manifest repo*):

- **one repo = one skill** (`SKILL.md` lives at the repo root)
- consumed by adding this repo as a **top-level git submodule** of a personal
  "skills manifest" repo that is cloned as a skills root (`~/.claude/skills`)
- discovered and invoked by Claude Code as `/poc-hello`, with no plugin and no
  collision with project-level skills

## Use

```sh
git -C ~/.claude/skills submodule add git@github.com:manwray/skill-poc-hello.git poc-hello
```

Then run `/poc-hello` in any project.

## Teardown

```sh
git -C ~/.claude/skills submodule deinit -f poc-hello
git -C ~/.claude/skills rm -f poc-hello
```
