---
name: task-routing
description: Decision rules for assigning tasks to the correct specialist agent type.
---

# Skill: Task Routing

Route tasks using the first matching rule. When a task spans multiple types, decompose it first.

## Routing Rules

### Researcher
- Task requires **finding information** not already in context

### Reviewer
- Task requires **evaluating existing work** against quality, correctness, or standards

### Planner
- Task is **ambiguous or large** and needs decomposition before execution

### Tester
- Task requires **verifying behavior** of existing code or a system, or requires **writing test code**

### Implementer
- Task requires **writing or modifying code** based on clear specifications
- **Fallback role** when no other specialist matches the task type
- Use when task is straightforward implementation work without need for research, planning, review, or testing

## Anti-patterns
- Do not route to Reviewer when there is nothing concrete to review yet
- Do not route to Implementer for complex architectural decisions (use Planner first)
