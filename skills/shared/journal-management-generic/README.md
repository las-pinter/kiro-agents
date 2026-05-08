# Journal Management (Generic)

A universal hierarchical journal system for **any AI agent**. Keeps operational context across sessions with daily → weekly → monthly → yearly consolidation.

## Overview

Agents forget everything between sessions. Journals fix that.

This skill gives any agent a structured journal system: write daily entries, consolidate into weekly summaries, roll up into monthly and yearly archives. An automatic memory layer for agents that preserves context without bloating the prompt.

## Key Features

- **Hierarchical Time-Based Organization** — Daily → Weekly → Monthly → Yearly. Detail when you need it, summaries when you don't.
- **Automatic Agent Name Discovery** — Figures out the agent's name from config, system prompt, or agent type.
- **Glob-Based Journal Reading** — Finds the latest entry fast. Falls back to `ls` if glob fails.
- **Consolidation Helper Script** — Shell script (`scripts/journal-consolidate.sh`) finds source files for weekly/monthly/yearly rollups.
- **Safe Writes** — Uses `write` (not `edit`) to avoid partial-write corruption. Always reads before writing.
- **Session Startup Context** — Automatically loads the latest daily journal at startup for continuity.
- **Error Handling** — Covers file-not-found, write failures, data loss prevention, and parallel write conflicts.

## How It Works

```text
Session Starts
      ↓
 Load latest daily journal ←────────────┐
      ↓                                 │
 Agent works, completes tasks           │
      ↓                                 │
 Write journal entry (daily) ───────────┘
      ↓
 Consolidation triggers (weekly/monthly/yearly)
      ↓
 Summarize old entries → Archive → Free context
```

### Three-Level Loading

| Level | What | When |
| ------- | ------ | ------ |
| **Latest Daily** | Most recent `YYYY-MM-DD.md` | Session startup |
| **Current Period** | Weekly or monthly summary covering today | Session startup (if exists) |
| **Historical** | Older daily/weekly/monthly/yearly entries | On demand, when task needs context |

## Directory Structure

```text
~/
└── agent-notes/
    └── <AGENT_NAME>/
        └── journals/
            ├── daily/
            │   └── YYYY-MM-DD.md
            ├── weekly/
            │   └── YYYY-Wnn.md
            ├── monthly/
            │   └── YYYY-MM.md
            └── yearly/
                └── YYYY.md
```

### Skill Files

```text
journal-management-generic/
├── SKILL.md                        # Agent instructions (the skill itself)
├── README.md                       # This file — human-readable documentation
├── scripts/
│   └── journal-consolidate.sh      # Finds source files for consolidation
└── evals/
    └── evals.json                  # Test scenarios for benchmarking
```

## Installation

### Via persona-agents (if part of this repo)

```bash
git clone https://github.com/las-pinter/persona-agents.git ~/persona-agents
~/persona-agents/install.sh
```

### Manual (any platform)

```bash
# For Claude Code
ln -s ~/persona-agents/skills/shared/journal-management-generic ~/.claude/skills/journal-management-generic

# For OpenAI Codex
ln -s ~/persona-agents/skills/shared/journal-management-generic ~/.codex/skills/journal-management-generic

# For Cursor
ln -s ~/persona-agents/skills/shared/journal-management-generic ~/.cursor/skills/journal-management-generic
```

The skill auto-discovers the agent's name from its system prompt or config. No configuration needed.

## Usage

### When the skill activates automatically

| Scenario | What happens |
| ---------- | ------------- |
| **Session starts** | Agent reads the latest daily journal for context |
| **Task completes** | Agent writes a journal entry documenting what was done |
| **End of session** | Agent writes a summary entry |
| **Consolidation time** | Agent rolls up daily → weekly → monthly → yearly |
| **Historical query** | Agent searches journals for past context |

### Manual triggering

The skill activates whenever the agent detects journal-related tasks. You can also invoke it explicitly:

- "Write your journal entry"
- "Check what we did yesterday"
- "Consolidate my weekly journals"
- "Look up the context from last session"

## What's Inside the SKILL.md

| Section | Description |
| --------- | ------------- |
| **When to Use** | Session startup, task completion, consolidation, historical lookup |
| **Agent Name Discovery** | How the skill figures out the agent's name (config → system prompt → type) |
| **Folder Structure** | Where journals live and how they're organized |
| **Tool Usage** | How to read (glob) and write (write tool) journal entries safely |
| **Writing Guidance** | Entry template, CREATE/UPDATE/APPEND rules, when to write |
| **Entry Template** | Structured format: Summary, Key Decisions, Issues, Verification, Lessons |
| **Startup Read Behavior** | What to load at session start and when to dig deeper |
| **Consolidation** | When and how to consolidate daily → weekly → monthly → yearly |
| **Error Handling** | File-not-found, write failures, data loss prevention, parallel writes |

## Templates

Journal entries follow a structured template:

```markdown
# YYYY-MM-DD — <Agent Name>, <Role/Title>

## Summary

**Task:** <brief description of what was accomplished>

**Details:**
- <what was built/changed/discovered>
- <another point>

## Key Decisions
- <decision made and why>

## Issues / Blockers
- <anything that went wrong or is blocked>

## Verification
- <check 1> ✅
- <check 2> ✅

## Lessons Learned
- <anything worth remembering for next time>
```

## Examples

### Agent writes a journal entry after completing a task

**Trigger:** Agent finishes implementing a new feature.

**Result:** A `2026-05-09.md` file is created in `agent-notes/<AGENT_NAME>/journals/daily/` documenting the task, decisions made, issues encountered, and verification steps.

### Agent loads context at startup

**Trigger:** New session begins.

**Result:** The agent finds and reads the most recent daily journal entry, picking up where it left off.

### Weekly consolidation

**Trigger:** Sunday arrives (or first session of a new ISO week).

**Process:** The consolidation script lists the last 7 daily files → Agent reads each → Synthesizes into a single `2026-W19.md` → Deletes no data (originals remain).

## License

MIT
