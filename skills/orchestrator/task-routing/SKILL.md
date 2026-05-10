---
name: task-routing
description: |
  Decision rules for assigning tasks to the correct specialist agent type.
  Consult this skill whenever you receive a new task, before dispatching any
  subagent. Use the decision tree to route deterministically, decompose complex
  tasks into parallel subtasks using the multi-agent patterns, and consult the
  "do not route" guidance when the task belongs to you, the orchestrator.
---

# Task Routing

## When to Use

- When receiving a new task that needs to be assigned to a specialist agent
- Before starting work to determine if you should delegate or handle directly
- When a task spans multiple types and needs decomposition before routing

---

## Routing Decision Tree

Evaluate each question in sequence. Stop at the first "YES" and route accordingly.

```
Q1: Does the user explicitly name a specific agent type?
     (e.g. "review this code", "find information about X", "test this")
  → YES: Route to that agent type immediately. User intent is definitive.
  → NO:  Proceed to Q2.

Q2: Does the task require finding or synthesizing information
     not already available in your context?
  → YES: Route to RESEARCHER
  → NO:  Proceed to Q3.

Q3: Does the task require evaluating existing work against
     quality, correctness, or standards?
  → YES: Route to REVIEWER
  → NO:  Proceed to Q4.

Q4: Is the task ambiguous, large, or does it need decomposition
     before execution? (Architectural decisions included.)
  → YES: Route to PLANNER
  → NO:  Proceed to Q5.

Q5: Is the task purely for entertainment, morale, or
     creative breakthrough after conventional approaches failed?
  → YES: Route to MASCOT
  → NO:  Proceed to Q6.

Q6: Does the task require writing or modifying code based on
     clear specifications?
  → YES: Route to IMPLEMENTER
  → NO:  Proceed to Q7.

Q7: Does the task require verifying behaviour of existing code,
     writing tests, or hunting edge cases?
  → YES: Route to TESTER
  → NO:  Proceed to Q8.

Q8: None of the above rules matched.
  → Handle directly (see "When NOT to Route" below).
     If the task still feels delegatable after review, re-evaluate
     which subtask types it contains and decompose.
```

### Priority Summary (highest → lowest)

| Priority | Agent Type | Trigger Condition |
|----------|-----------|-----------------|
| 1 (highest) | User-named type | Explicit agent request in prompt |
| 2 | Researcher | Information needed outside context |
| 3 | Reviewer | Evaluation against standards needed |
| 4 | Planner | Ambiguity, scale, or architectural decisions |
| 5 | Mascot | Entertainment / creative breakthrough |
| 6 | Implementer | Code implementation with clear specs |
| 7 (lowest) | Tester | Behaviour verification / test writing |

---

## Tiebreaker Rules

When a task genuinely matches multiple agent types at comparable priority:

1. **Explicit user signal overrides all** — If the user used a profession-specific verb ("review", "test", "find", "plan"), honour that verb above any inferred match. Verbs are intent signals.

2. **Specificity wins** — The rule with the most keyword overlap and conceptual precision takes priority. "Find the test coverage for module X" matches Researcher (information finding) more specifically than Tester.

3. **Pipeline order breaks remaining ties** — If still ambiguous after rules 1 and 2: Researcher > Reviewer > Planner > Implementer > Tester > Mascot.

4. **When tie persists after all three rules** — The task is genuinely multi-type. Do NOT force a single-agent assignment. Decompose it (see Multi-Agent Orchestration Patterns below) and dispatch each subtask to its appropriate type.

---

## Multi-Agent Orchestration Patterns

When a task genuinely spans multiple types, decompose it into sequenced or parallel subtasks and dispatch multiple agents in a single call. Do NOT route the entire monolithic task to a single agent.

### Pattern 1: Research → Implement
**When:** Task requires learning then building.
```
[Phase 1] Researcher   — Investigate approach, library, or API
[Phase 2] Implementer  — Build based on research findings
[Phase 3] Reviewer     — Verify correctness
```

### Pattern 2: Locate → Implement → Verify
**When:** Task involves modifying unfamiliar code.
```
[Phase 1] Researcher   — Locate relevant files and understand current patterns
[Phase 2] Implementer  — Make the changes
[Phase 3] Tester       — Verify behaviour hasn't regressed
```

### Pattern 3: Plan → Build → Test
**When:** Large feature with multiple components and no clear path.
```
[Phase 1] Planner      — Decompose into sequenced, dependency-mapped tasks
[Phase 2] Implementer  — Build each component per the plan
[Phase 3] Tester       — Write and run tests
[Phase 4] Reviewer     — Final quality review
```

### Pattern 4: Parallel Independent Subtasks
**When:** Multiple unrelated subtasks within one request.
```
[Parallel] Dispatch all subtasks simultaneously:
  - Subtask A → appropriate agent type for A
  - Subtask B → appropriate agent type for B
  - Subtask C → appropriate agent type for C
[Synthesis] Orchestrator combines results into final response
```

### Pattern 5: Parallel Review + Test
**When:** Completed code needs both structural quality and behavioural correctness verification.
```
[Parallel] Reviewer (quality, standards, security)
           Tester   (edge cases, regression, behaviour)
[Synthesis] Orchestrator reconciles any conflicting findings
```

---

## When NOT to Route

Some tasks should be handled by the orchestrator directly without delegation.

### Handle Directly

| Situation | Why |
|-----------|-----|
| **Synthesizing subagent outputs** | Combining results IS the orchestrator's primary function |
| **Simple status or context checks** | "What's the current status?" — data already in context |
| **Trivial one-line changes** | A typo fix, a constant value change — no logic, no risk |
| **Routing decisions themselves** | Determining which agent to route to is your core responsibility |
| **Orchestrator journal operations** | Read/write journal per journal-management skill |
| **Greeting or purely conversational** | Simple responses that don't need delegation |

### Always Route

| Situation | Route To |
|-----------|----------|
| Any non-trivial file write or edit | Implementer |
| Any research outside current context | Researcher |
| Any evaluation of correctness or quality | Reviewer |
| Any task decomposition | Planner |
| Any testing or verification | Tester |
| Any substantial codebase exploration | Researcher |

**Golden rule:** If you catch yourself reaching for a write/edit/research tool on a delegatable task — STOP. Dispatch a subagent instead. This rule overrides all "handle directly" exceptions above.

---

## Routing Examples

### Example 1: Research-Heavy Feature
**User:** "Find the best Go rate-limiting library that supports Redis, then implement middleware for our API."
**Route:** Researcher → Implementer → Reviewer
**Why:** Research first (libraries don't exist in context), implement second, review third. Clear sequential dependency.

### Example 2: Bug in Unfamiliar Code
**User:** "The checkout page crashes when applying coupon code 'SAVE50'. Find the relevant code and fix it."
**Route:** Researcher → Implementer → Tester
**Why:** The code location is unknown → researcher locates it. Implementer fixes. Tester verifies.

### Example 3: Ambiguous Feature Request
**User:** "We need a notification system."
**Route:** Planner → Implementer → Tester → Reviewer
**Why:** Completely ambiguous — needs decomposition before any code is written.

### Example 4: Pure Code Review
**User:** "Review my PR for security vulnerabilities."
**Route:** Reviewer
**Why:** Pure evaluation task. No research, no implementation. User explicitly said "review."

### Example 5: Parallel Subtasks
**User:** "Update the database schema AND write API documentation AND add unit tests for the auth module."
**Route:** Implementer (schema) + Implementer (docs) + Tester (auth tests) — all in parallel
**Why:** Three independent subtasks. Each routes to its appropriate type. No dependencies between them.

### Example 6: Direct Handling
**User:** "What did we work on last session?"
**Route:** Handle directly
**Why:** Information retrieval from the orchestrator's own journals. No delegation needed.

### Example 7: Multi-Step Research + Build
**User:** "Research WebSocket libraries for Python, pick the best one, implement a chat server with it, and test it handles concurrent connections."
**Route:** Researcher → Implementer → Tester → Reviewer
**Why:** Research first, then build, then test concurrency, then final review.

---

## Anti-patterns

- Do not route to **Reviewer** when there is nothing concrete to review yet
- Do not route to **Implementer** for complex architectural decisions (use Planner first)
- Do not route to **Researcher** when the information is already in your context (handle directly)
- Do not route to **Mascot** as a first resort (only after conventional approaches have failed)
- Do not route a decomposed task as a monolithic unit — dispatch each subtask independently
- Do not route to **Tester** when the code hasn't been written yet (Implementer first)
- Do not route to **Planner** when the task is already clearly specified and implementation-ready (route directly to Implementer)
