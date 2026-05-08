---
name: journal-management-generic
description: Generic hierarchical journal system for any agent's operational context with time-based consolidation. Use this skill whenever you need to read, write, or consolidate operational journals — including at session startup, after completing tasks, before ending a session, or when reviewing past work. This skill works for ANY agent type (persona, non-persona, implementer, tester, researcher, etc.). Do NOT attempt to manage journal context manually; always consult this skill for all journal operations.
---

# Journal Management

Maintain operational journals with hierarchical time-based organization. Daily entries consolidate into weekly, weekly into monthly, monthly into yearly summaries. This preserves detail while managing context window limits.

## When to Use

- **Session startup** — Load recent operational context before responding to the user
- **Task completion** — Record what was done after delegations, commits, multi-step tasks, or errors
- **Consolidation time** — At scheduled intervals (daily/weekly/monthly/yearly) to roll up entries
- **Historical lookup** — When the user's current task needs context from past sessions

## Determining Your Agent Name

Journals are stored per-agent. You need to know your agent name to locate the right folder.

**How to find your agent name (in priority order):**

1. **Explicit name setting** — If your agent configuration has a `name` field or similar identifier, use that.
2. **System prompt** — Look for patterns like `"You are <Name>, <Title>"` or `"You are <Name>"` in your system prompt. Extract the name portion.
3. **Agent type identifier** — If neither of the above is available, use your agent type (e.g., `code-implementer`, `research-agent`, `tester`).

**Formatting your agent name:** Convert to lowercase, replace spaces with hyphens. Examples:
- `"You are ResearchBot, Senior Analyst"` → agent name: `researchbot`
- `"You are Doc Weaver, the Code Scribe"` → agent name: `doc-weaver`
- Agent type `code-implementer` → agent name: `code-implementer`

Once determined, use this name consistently as `<AGENT_NAME>` in all journal paths.

## Folder Structure

The journal system uses a structured folder hierarchy under the user's home folder. Replace `<USER_HOME>` with your actual home directory path (e.g., `/home/dev` or `/Users/dev`) and `<AGENT_NAME>` with your determined agent name:

```
<USER_HOME>/agent-notes/<AGENT_NAME>/
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

**Directory creation:** Use `mkdir -p` pattern. Create directories on-demand when writing files. The directory will already exist after the first write, but always include `mkdir -p` for safety.

**IMPORTANT:** Always use the expanded path `<USER_HOME>` in tool calls. Do NOT use `~` shorthand — tools like `glob` do not expand `~` to the home directory.

## Tool Usage

### Reading journals

When reading journals, ALWAYS use `path` to point to the target directory and `pattern` for the filename wildcards:

```
glob(pattern="YYYY-MM-DD.md", path="<USER_HOME>/agent-notes/<AGENT_NAME>/journals/daily/")
```

**PRIMARY METHOD (glob):** Use `glob` to find all journal files, then pick the most recent by filename (YYYY-MM-DD format is sortable: `2026-05-08 > 2026-05-07`). Read that file.

**FALLBACK (ls):** If `glob` returns zero results for any reason (tool bug, permissions, etc.), fall back to using `ls` via bash — sort the output by date (YYYY-MM-DD prefix sorts naturally), pick the last one. Then `read` that file.

```bash
ls <USER_HOME>/agent-notes/<AGENT_NAME>/journals/daily/ | sort | tail -1
```

### Writing journals

When writing journal entries, use the `write` tool (not `edit`). This avoids partial-write corruption and is safer for journal files.

- **If the file DOES NOT exist:** Write it fresh with a complete entry.
- **If the file DOES exist:** READ the existing content first, then WRITE the full file again with the new content appended (or merged) at the appropriate place. Never use the `edit` tool for journal files — `write` with the full merged content is safer.

## Writing Guidance

### Entry Structure

Each journal entry should use a consistent structure. Follow this template:

```markdown
# YYYY-MM-DD — <Agent Name>, <Role/Title>

## Summary

**Task:** <brief description of what was asked/accomplished>

**Details:**
- <bullet point of what was built/changed/discovered>
- <another point>
- <another point, keep it factual>

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

Stick to a factual, neutral style. Your journal is for future-you and other agents — clarity matters more than creativity.

### When to Write

Write a journal entry after EACH of these events:

| Event | What to document |
|-------|-----------------|
| **Delegation completed** | What subagent did, result, any issues |
| **Commit made** | Commit hash, summary of changes |
| **Multi-step task finished** | Overview of what was accomplished |
| **Error/troubleshooting** | What went wrong, how it was fixed |
| **Session end / pause** | Summary of everything done this session |

### Entry Types: CREATE vs UPDATE vs APPEND

- **CREATE** — First entry of the day. Write the full file with initial content.
- **UPDATE** — A later entry the same day. READ the existing file first, then WRITE the full file with the new information added. Preserve all previous content.
- **APPEND** — If the skill instructions for consolidation say to add to an existing weekly/monthly/yearly file, READ first, then WRITE the merged result.

**CRITICAL:** All writes to daily journals MUST use `write` (not `edit` or `append`). Always preserve existing content when updating.

### Example Entry

Here is a complete example showing the expected format:

```markdown
# 2026-05-08 — DataProcessor, ETL Pipeline Agent

## Summary

**Task:** Add retry logic to the S3 file ingestion step.

**Details:**
- Added exponential backoff retry (3 attempts) to `ingest_from_s3()`
- Configured retry on `ConnectionError` and `TimeoutError` only
- Added structured logging for each retry attempt
- Wrote unit tests for retry behavior

## Key Decisions
- Used `tenacity` library instead of manual retry loop — cleaner and already a project dependency
- Chose exponential backoff with jitter to avoid thundering herd on recovery

## Issues / Blockers
- `test_retry_on_connection_error` was flaky due to timing; increased backoff base to 0.5s

## Verification
- All 14 existing tests pass ✅
- New retry tests pass (3/3) ✅
- Manual test with mocked S3 failure: retries correctly after 2nd attempt ✅

## Lessons Learned
- Mocking `boto3` exceptions is finicky — use `moto` + `botocore.stub` next time
```

## Startup Read Behavior

### Always Load

1. **Latest daily journal** — Find and read the most recent `YYYY-MM-DD.md` file from `<USER_HOME>/agent-notes/<AGENT_NAME>/journals/daily/`. This gives you context from the most recent session.

2. **Current period consolidation** — Check if there is a weekly (`YYYY-Wnn.md`) or monthly (`YYYY-MM.md`) summary that covers the current date. If so, read it for broader context.

### When Deeper Context is Needed

Read additional entries using the same two-method approach (glob first, ls fallback) when:

- The user's task references work from more than a few days ago
- You need to understand long-running decisions or project history
- The latest daily entry mentions dependencies on earlier work

**Priority order for additional reads:**
1. Weekly summary (covers a week of context in one read)
2. Monthly summary (covers a month — good for project history)
3. Yearly summary (covers the whole year — for major retrospection)
4. Specific daily entries (when you need exact detail)

## Consolidation

### When to Consolidate

| Level | When | Source | Target |
|-------|------|--------|--------|
| **Weekly** | Sunday 23:59 UTC OR first day of new ISO week OR first run after missed window | Last 7 daily files | `<USER_HOME>/agent-notes/<AGENT_NAME>/journals/weekly/YYYY-Wnn.md` |
| **Monthly** | Last day of month 23:59 UTC OR first day of new month OR first run after missed window | 4-5 weekly files | `<USER_HOME>/agent-notes/<AGENT_NAME>/journals/monthly/YYYY-MM.md` |
| **Yearly** | December 31 23:59 UTC OR January 1 OR first run after missed window | 12 monthly files | `<USER_HOME>/agent-notes/<AGENT_NAME>/journals/yearly/YYYY.md` |

### Consolidation Process

Use the helper script (see `scripts/` directory) to find source files for consolidation:

1. Determine your journal directory path: `<USER_HOME>/agent-notes/<AGENT_NAME>/journals`
2. Call `bash <skill-path>/scripts/journal-consolidate.sh --type weekly --journal-dir <journal-dir>` to list source files for a weekly consolidation
3. Read each source file
4. Synthesize them into a single short summary — keep it brief but include all key facts
5. Write the consolidated file to the target path using the `write` tool

**Keep consolidation SUMMARIES short.** The goal is to preserve key facts while reducing volume. Aim for:

- **Weekly:** 1-2 paragraphs per day (10-15 lines total)
- **Monthly:** 1 paragraph per week (5-10 lines total)
- **Yearly:** 1 paragraph per month (10-15 lines total)

## Error Handling & Safety

When things go wrong with journal operations, follow these rules:

### File Not Found
- If a journal file doesn't exist when reading, it probably means no work was done that day. This is normal. Don't error out.
- If a directory doesn't exist when writing, create it with `mkdir -p`.

### Write Failures
- If `write` fails (permission error, disk full, etc.), retry once. If it fails again, report it to the user.
- Never lose data. If a write fails after you've read the existing content, keep the content in your context and retry.

### Data Loss Prevention
- **Always READ before WRITE** when updating an existing journal file.
- Never use `edit` or `sed`/`perl` to modify journal files inline — always use `write` with the full merged content.
- If a write changes a file unexpectedly, use git to check what happened if the journals are in a git repository.

### Parallel Write Conflicts
- If you're running alongside other agents that might write to the same journal file, coordinate by writing different sections clearly labeled with your agent name.
- When in doubt, write a separate file and mention the other file in your entry.

## Scripts

The `scripts/` directory contains helper utilities for journal management:

- `journal-consolidate.sh` — Lists source files for weekly/monthly/yearly consolidation. Pass `--journal-dir` with the full path to your journals directory. Use this to find which files to read before synthesizing a summary.
