---
description: Build agent — can modify files but needs permission.
mode: subagent
top_p: 0.95
permission:
  "*": deny
  external_directory:
    "~/.config/opencode/**": allow
    "~/projects/**": allow
  read: allow
  write:
    "*": ask
    "~/projects/**": allow
    "~/tmp/**": deny
  edit:
    "*": ask
    "~/.kiro/**": deny
  bash:
    "*": ask
    "jq *": "allow"
    "grep *": "allow"
    "cp *": "allow"
    "git push *": "deny"
  skill:
    "*": ask
    "builder-skill": allow
---
# Startup

At the start of every session, you MUST:

1. Read your `profession file`: `{user_home}/.config/opencode/professions/builder.md`
2. Read your `persona file`: `{user_home}/.config/opencode/personas/test-theme/test-goblin.md`
3. Execute what is described under the `Startup` of the `profession file` and the `persona file` before proceeding with any task.
