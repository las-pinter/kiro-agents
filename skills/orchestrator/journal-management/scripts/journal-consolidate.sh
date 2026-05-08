#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────
#  journal-consolidate.sh — Find journal source files for consolidation
# ─────────────────────────────────────────────────────────────────
#  Usage:
#    bash journal-consolidate.sh --type weekly|monthly|yearly \
#      --agent-suffix SUFFIX [--date YYYY-MM-DD] [--journal-dir PATH]
#
#  Options:
#    --type TYPE       Consolidation type: weekly, monthly, or yearly (required)
#    --agent-suffix S  Agent suffix like 'bossnik', 'grimgob' (required)
#    --date DATE       Reference date (default: today, format: YYYY-MM-DD)
#    --journal-dir DIR Journal base directory (default: ~/agent-notes/orchestrator/journals)
#    --help, -h        Show this help
#
#  Output:
#    Prints the list of source files to consolidate, one per line.
#    Also prints the target file path as the last line prefixed with "TARGET:".
#
#  Example:
#    bash journal-consolidate.sh --type weekly --agent-suffix bossnik
#    # → Lists last 7 daily files for Bossnik's weekly consolidation
# ─────────────────────────────────────────────────────────────────

set -euo pipefail

# ── Defaults ────────────────────────────────────────────────────
TYPE=""
AGENT_SUFFIX=""
REF_DATE=$(date +%Y-%m-%d)
JOURNAL_DIR="$HOME/agent-notes/orchestrator/journals"

# ── Arg parsing ──────────────────────────────────────────────────
usage() {
    echo "Usage: $0 --type TYPE --agent-suffix SUFFIX [--date YYYY-MM-DD] [--journal-dir DIR]"
    echo ""
    echo "Types: weekly, monthly, yearly"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
    --type=*)
        TYPE="${1#--type=}"
        shift
        ;;
    --type)
        if [[ -z "$2" || "$2" == --* ]]; then
            echo "Error: --type requires a value (weekly, monthly, yearly)" >&2
            exit 1
        fi
        TYPE="$2"
        shift 2
        ;;
    --agent-suffix=*)
        AGENT_SUFFIX="${1#--agent-suffix=}"
        shift
        ;;
    --agent-suffix)
        if [[ -z "$2" || "$2" == --* ]]; then
            echo "Error: --agent-suffix requires a value" >&2
            exit 1
        fi
        AGENT_SUFFIX="$2"
        shift 2
        ;;
    --date=*)
        REF_DATE="${1#--date=}"
        shift
        ;;
    --date)
        if [[ -z "$2" || "$2" == --* ]]; then
            echo "Error: --date requires a value (YYYY-MM-DD)" >&2
            exit 1
        fi
        REF_DATE="$2"
        shift 2
        ;;
    --journal-dir=*)
        JOURNAL_DIR="${1#--journal-dir=}"
        shift
        ;;
    --journal-dir)
        if [[ -z "$2" || "$2" == --* ]]; then
            echo "Error: --journal-dir requires a value" >&2
            exit 1
        fi
        JOURNAL_DIR="$2"
        shift 2
        ;;
    --help | -h)
        usage
        ;;
    *)
        echo "Unknown option: $1" >&2
        usage
        ;;
    esac
done

# ── Validation ───────────────────────────────────────────────────
if [[ -z "$TYPE" ]]; then
    echo "Error: --type is required (weekly, monthly, or yearly)" >&2
    exit 1
fi
if [[ -z "$AGENT_SUFFIX" ]]; then
    echo "Error: --agent-suffix is required" >&2
    exit 1
fi
if [[ "$TYPE" != "weekly" && "$TYPE" != "monthly" && "$TYPE" != "yearly" ]]; then
    echo "Error: --type must be 'weekly', 'monthly', or 'yearly', got '$TYPE'" >&2
    exit 1
fi

# Validate date format
if ! date -d "$REF_DATE" >/dev/null 2>&1; then
    echo "Error: invalid date '$REF_DATE'. Use YYYY-MM-DD format." >&2
    exit 1
fi

YEAR=$(date -d "$REF_DATE" +%Y)
MONTH=$(date -d "$REF_DATE" +%m)
MONTH_NUM=$((10#$MONTH))
WEEK_NUM=$(date -d "$REF_DATE" +%V)  # ISO week number

# ── Weekly consolidation ─────────────────────────────────────────
weekly_consolidate() {
    local daily_dir="$JOURNAL_DIR/daily"

    if [[ ! -d "$daily_dir" ]]; then
        echo "Error: daily journal directory not found: $daily_dir" >&2
        exit 1
    fi

    # Find all daily files for this agent, sorted newest first
    local all_files
    all_files=$(find "$daily_dir" -name "*-$AGENT_SUFFIX.md" -type f 2>/dev/null | sort -r)

    if [[ -z "$all_files" ]]; then
        echo "Error: no daily journal files found for suffix '$AGENT_SUFFIX'" >&2
        exit 1
    fi

    # Take the last 7 (or fewer) — since we sorted -r, tail gets oldest ones first
    local source_files
    source_files=$(echo "$all_files" | head -7 | sort)

    if [[ -z "$source_files" ]]; then
        echo "Error: no daily files to consolidate" >&2
        exit 1
    fi

    # Print source files
    echo "$source_files"

    # Print target
    local target="$JOURNAL_DIR/weekly/$YEAR-W$WEEK_NUM-$AGENT_SUFFIX.md"
    echo "TARGET:$target"
}

# ── Monthly consolidation ────────────────────────────────────────
monthly_consolidate() {
    local weekly_dir="$JOURNAL_DIR/weekly"

    if [[ ! -d "$weekly_dir" ]]; then
        echo "Error: weekly journal directory not found: $weekly_dir" >&2
        exit 1
    fi

    # Find weekly files for this agent and this month/year
    # ISO weeks can span months, so we look at weeks that belong to this month
    # A simple heuristic: find files with the year-month prefix in the week
    local source_files
    source_files=$(find "$weekly_dir" -name "$YEAR-W*-$AGENT_SUFFIX.md" -type f 2>/dev/null | sort)

    if [[ -z "$source_files" ]]; then
        echo "Error: no weekly journal files found for '$YEAR' and suffix '$AGENT_SUFFIX'" >&2
        exit 1
    fi

    # Limit to last 5 (about a month's worth)
    source_files=$(echo "$source_files" | tail -5)

    echo "$source_files"
    local target="$JOURNAL_DIR/monthly/$YEAR-$MONTH-$AGENT_SUFFIX.md"
    echo "TARGET:$target"
}

# ── Yearly consolidation ─────────────────────────────────────────
yearly_consolidate() {
    local monthly_dir="$JOURNAL_DIR/monthly"

    if [[ ! -d "$monthly_dir" ]]; then
        echo "Error: monthly journal directory not found: $monthly_dir" >&2
        exit 1
    fi

    # Find all monthly files for this year
    local source_files
    source_files=$(find "$monthly_dir" -name "$YEAR-*-$AGENT_SUFFIX.md" -type f 2>/dev/null | sort)

    if [[ -z "$source_files" ]]; then
        echo "Error: no monthly journal files found for '$YEAR' and suffix '$AGENT_SUFFIX'" >&2
        exit 1
    fi

    echo "$source_files"
    local target="$JOURNAL_DIR/yearly/$YEAR-$AGENT_SUFFIX.md"
    echo "TARGET:$target"
}

# ── Main ─────────────────────────────────────────────────────────
case "$TYPE" in
weekly)
    weekly_consolidate
    ;;
monthly)
    monthly_consolidate
    ;;
yearly)
    yearly_consolidate
    ;;
esac
