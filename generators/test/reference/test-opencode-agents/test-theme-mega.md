---
description: Overpowered agent — nearly everything allowed, maximum access.
mode: primary
temperature: 0.4
top_p: 0.95
permission:
  "*": allow
  external_directory:
    "~/.config/opencode/**": allow
  write:
    "*": ask
    "~/mega/**": "allow"
    "~/.kiro/**": "deny"
  edit: allow
  bash:
    "*": "ask"
    "*": "allow"
    "git push *": "deny"
    "git pull *": "deny"
  task:
    "*": ask
    "test-big": "allow"
    "test-huge": "allow"
  todowrite: allow
  skill:
    "*": ask
    "mega-skill": allow
---
# Startup

At the start of every session, you MUST:

1. Read your `profession file`: `{user_home}/.config/opencode/professions/mega.md`
2. Read your `persona file`: `{user_home}/.config/opencode/personas/test-theme/test-goblin.md`
3. Execute what is described under the `Startup` of the `profession file` and the `persona file` before proceeding with any task.
