---
name: task-decomposition
description: Break down a feature or requirement into independently completable, estimated, dependency-mapped tasks.
---

# Task Decomposition

## When to Use

When breaking down a feature, epic, or requirement into executable tasks.

## Procedure

1. **Identify the goal** — one sentence: what does done look like?
1. **Identify the layers** — UI, API, data, infra, tests, docs. Which are affected?
1. **Break into tasks** — each task must be independently completable and verifiable
1. **Map dependencies** — which tasks block others? Draw the order explicitly
1. **Estimate complexity** — small (< 2 hours), medium (2–8 hours), large (> 8 hours). If large, decompose further.
1. **Assign acceptance criteria** — each task needs a clear definition of done

## Rules

- No task should depend on an unplanned task
- If a task cannot be estimated, it has unresolved unknowns, surface them first
- Prefer more smaller tasks over fewer large ones
