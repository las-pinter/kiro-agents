#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────
#  journal-consolidate.sh — Find journal source files for consolidation
# ─────────────────────────────────────────────────────────────────
#  Usage:
#    bash journal-consolidate.sh --type weekly|monthly|yearly \
#      [--date YYYY-MM-DD] [--journal-dir PATH]
#
#  Options:
#    --type TYPE       Consolidation type: weekly, monthly, or yearly (required)
#    --date DATE       Reference date (default: today, format: YYYY-MM-DD)
#    --journal-dir DIR Journal base directory with daily/weekly/monthly/yearly subdirs
#                      (default: ~/agent-notes/<AGENT_NAME>/journals)
#    --help, -h        Show this help
#
#  Output:
#    Prints the list of source files to consolidate, one per line.
#    Also prints the target file path as the last line prefixed with "TARGET:".
#
#  Example:
#    bash journal-consolidate.sh --type weekly --journal-dir ~/agent-notes/my-agent/journals
#    # → Lists last 7 daily files for consolidation
# ─────────────────────────────────────────────────────────────────

set -euo pipefail

# ── Defaults ────────────────────────────────────────────────────
TYPE=""
REF_DATE=$(date +%Y-%m-%d)
JOURNAL_DIR=""

# ── Arg parsing ──────────────────────────────────────────────────
usage() {
    echo "Usage: $0 --type TYPE [--date YYYY-MM-DD] [--journal-dir DIR]"
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
if [[ -z "$JOURNAL_DIR" ]]; then
    echo "Error: --journal-dir is required (e.g., ~/agent-notes/my-agent/journals)" >&2
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
WEEK_NUM=$(date -d "$REF_DATE" +%V)  # ISO week number

# Expand tilde if present
JOURNAL_DIR="${JOURNAL_DIR/#\~/$HOME}"

# ── Weekly consolidation ─────────────────────────────────────────
weekly_consolidate() {
    local daily_dir="$JOURNAL_DIR/daily"

    if [[ ! -d "$daily_dir" ]]; then
        echo "Error: daily journal directory not found: $daily_dir" >&2
        exit 1
    fi

    # Find all daily markdown files, sorted newest first
    local all_files
    all_files=$(find "$daily_dir" -maxdepth 1 -name "????-??-??.md" -type f 2>/dev/null | sort -r) || true

    if [[ -z "$all_files" ]]; then
        echo "Error: no daily journal files found in $daily_dir" >&2
        exit 1
    fi

    # Take the 7 newest files — we sorted -r, so head gets the newest
    local source_files
    source_files=$(echo "$all_files" | head -n 7 | sort)

    if [[ -z "$source_files" ]]; then
        echo "Error: no daily files to consolidate" >&2
        exit 1
    fi

    # Print source files
    echo "$source_files"

    # Print target
    local target="$JOURNAL_DIR/weekly/$YEAR-W$WEEK_NUM.md"
    echo "TARGET:$target"
}

# ── Monthly consolidation ────────────────────────────────────────
monthly_consolidate() {
    local weekly_dir="$JOURNAL_DIR/weekly"

    if [[ ! -d "$weekly_dir" ]]; then
        echo "Error: weekly journal directory not found: $weekly_dir" >&2
        exit 1
    fi

    # Find weekly files for this year
    local source_files
    source_files=$(find "$weekly_dir" -maxdepth 1 -name "$YEAR-W*.md" -type f 2>/dev/null | sort) || true

    if [[ -z "$source_files" ]]; then
        echo "Error: no weekly journal files found for '$YEAR' in $weekly_dir" >&2
        exit 1
    fi

    # Limit to last 5 (about a month's worth)
    source_files=$(echo "$source_files" | tail -n 5)

    echo "$source_files"
    local target="$JOURNAL_DIR/monthly/$YEAR-$MONTH.md"
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
    source_files=$(find "$monthly_dir" -maxdepth 1 -name "$YEAR-*.md" -type f 2>/dev/null | sort) || true

    if [[ -z "$source_files" ]]; then
        echo "Error: no monthly journal files found for '$YEAR' in $monthly_dir" >&2
        exit 1
    fi

    echo "$source_files"
    local target="$JOURNAL_DIR/yearly/$YEAR.md"
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
