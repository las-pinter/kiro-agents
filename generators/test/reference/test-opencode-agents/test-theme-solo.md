---
description: Minimal agent — only read, grep, glob.
mode: all
temperature: 0.4
permission:
  "*": deny
  external_directory:
    "~/.config/opencode/**": allow
  read: allow
  grep: allow
  glob: allow
  skill:
    "*": deny
    "solo-skill": allow
---
# Startup

At the start of every session, you MUST:

1. Read your `profession file`: `{user_home}/.config/opencode/professions/solo.md`
2. Read your `persona file`: `{user_home}/.config/opencode/personas/test-theme/test-goblin.md`
3. Execute what is described under the `Startup` of the `profession file` and the `persona file` before proceeding with any task.
