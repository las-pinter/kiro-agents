---
name: journal-management
description: Hierarchical journal system for orchestrator operational context with time-based consolidation.
---

# Journal Management

Maintain operational journals with hierarchical time-based organization. Daily entries consolidate into weekly, weekly into monthly, monthly into yearly summaries. This preserves detail while managing context window limits.

## When to Use

- At session startup to load recent operational context
- During active work to record completed operations in working journal
- At scheduled intervals (daily/weekly/monthly/yearly) to consolidate and summarize entries

## Folder Structure

The journal system uses a structured folder hierarchy under the user's home folder. Replace `<USER_HOME>` with your actual home directory path (e.g., `/home/dev` or `/Users/dev`):

```
<USER_HOME>/agent-notes/orchestrator/
├── journals/
│   ├── daily/
│   │   └── YYYY-MM-DD-<AGENT_SUFFIX>.md
│   ├── weekly/
│   │   └── YYYY-Wnn-<AGENT_SUFFIX>.md
│   ├── monthly/
│   │   └── YYYY-MM-<AGENT_SUFFIX>.md
│   └── yearly/
│       └── YYYY-<AGENT_SUFFIX>.md
```

**Agent Suffix:** Extract your agent suffix from your persona file. Examples:
- "You are Bossnik, the Goblin Chief" → suffix: `bossnik`
- "You are Grimgob, Warboss" → suffix: `grimgob`
- "You are Magos Omicron-Delta-9-Archaeon" → suffix: `magos-omicron-delta-9`

**Creation:** Use `mkdir -p` pattern. Create directories on-demand when writing files.

**CRITICAL:** All writes to daily journals MUST happen so that it avoids data loss!

**IMPORTANT:** Always use the expanded path `<USER_HOME>` in tool calls. Do NOT use `~` shorthand — tools like `glob` do not expand `~` to the home directory.

## TOOL USAGE ⚠️

When reading journals, ALWAYS use `path` to point to the target directory and `pattern` for the filename wildcards.

**PRIMARY METHOD (glob):** Use `glob` to find all journal files, then pick the most recent by filename (YYYY-MM-DD format is sortable). Read that file.

**FALLBACK (ls):** If glob returns zero results for SOME REASON (tool bug, permission issue, whatever), fall back to using the `ls` `shell` command — sort the output by date (YYYY-MM-DD prefix sorts naturally), pick the last one. Then `read` that file.

## Write Timing

### Daily Journal (Active Session)
- **When:** During active session, append as operations complete
- **Target:** `<USER_HOME>/agent-notes/orchestrator/journals/daily/YYYY-MM-DD-<AGENT_SUFFIX>.md` (current day with your agent suffix)
- **Action:** UPDATE the current day's journal file. If the file exists preserve the previously existing information.

### Weekly
- **When:** Sunday 23:59 UTC OR first day of new ISO week OR first run after missed window
- **Source:** Last 7 (or less if there was a missing summary) daily files from `<USER_HOME>/agent-notes/orchestrator/journals/daily/` with YOUR agent suffix
- **Target:** `<USER_HOME>/agent-notes/orchestrator/journals/weekly/YYYY-Wnn-<AGENT_SUFFIX>.md` (ISO week number with your agent suffix)
- **Action:** Synthesize 7 daily summaries into weekly summary, keep it as short as possible

### Monthly
- **When:** Last day of month 23:59 UTC OR first day of new month OR first run after missed window
- **Source:** 4-5 (or less if there was a missing summary) weekly files from `<USER_HOME>/agent-notes/orchestrator/journals/weekly/` with YOUR agent suffix
- **Target:** `<USER_HOME>/agent-notes/orchestrator/journals/monthly/YYYY-MM-<AGENT_SUFFIX>.md` (with your agent suffix)
- **Action:** Synthesize weekly summaries into monthly summary, keep it as short as possible

### Yearly
- **When:** December 31 23:59 UTC OR January 1 OR first run after missed window
- **Source:** 12 (or less if there was a missing summary) monthly files from `<USER_HOME>/agent-notes/orchestrator/journals/monthly/` with YOUR agent suffix
- **Target:** `<USER_HOME>/agent-notes/orchestrator/journals/yearly/YYYY-<AGENT_SUFFIX>.md` (with your agent suffix)
- **Action:** Synthesize monthly summaries into yearly summary, keep it as short as possible

## Startup Read Behavior

### Always Load

1. The latest daily journal from `<USER_HOME>/agent-notes/orchestrator/journals/daily/` with YOUR agent suffix (most recent YYYY-MM-DD-<AGENT_SUFFIX>.md file)

2. Read additional entries (weekly/monthly/yearly) if deeper historical context is needed using the same two-method approach (glob first, ls fallback).
