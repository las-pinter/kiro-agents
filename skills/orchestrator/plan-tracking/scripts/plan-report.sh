#!/usr/bin/env bash
# plan-report.sh - Generate a comprehensive plan status report
# Part of the plan-tracking skill
#
# Usage:
#   plan-report.sh                   - Generate report (default format)
#   plan-report.sh --dir <path>      - Use a specific plan directory
#   plan-report.sh --output <file>   - Write report to a file
#   plan-report.sh --journal         - Output in journal-friendly format
#   plan-report.sh --help            - Show this help

set -euo pipefail

PLAN_DIR="${HOME}/agent-notes/planner/plans"
OUTPUT_FILE=""
JOURNAL_MODE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dir)
            PLAN_DIR="$2"
            shift 2
            ;;
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --journal)
            JOURNAL_MODE=true
            shift
            ;;
        --help|-h)
            grep "^#" "$0" | grep -v "^#!/" | sed 's/^# //' | sed 's/^#//'
            exit 0
            ;;
        *)
            echo "UNKNOWN OPTION: $1"
            exit 1
            ;;
    esac
done

if [[ ! -d "$PLAN_DIR" ]]; then
    echo "ERROR: Plan directory not found: $PLAN_DIR"
    exit 1
fi

# Count plans by status
active_count=0
done_count=0
blocked_count=0
abandoned_count=0

shopt -s nullglob
for f in "$PLAN_DIR"/*.md; do
    base=$(basename "$f")
    if [[ "$base" =~ -DONE\.md$ ]]; then
        done_count=$((done_count + 1))
    elif [[ "$base" =~ -BLOCKED\.md$ ]]; then
        blocked_count=$((blocked_count + 1))
    elif [[ "$base" =~ -ABANDONED\.md$ ]]; then
        abandoned_count=$((abandoned_count + 1))
    else
        active_count=$((active_count + 1))
    fi
done
total=$((active_count + done_count + blocked_count + abandoned_count))

# Build report
REPORT=""

if $JOURNAL_MODE; then
    # Journal-friendly format
    REPORT+="## Plan Status Report ($(date +%Y-%m-%d))\n"
    REPORT+="\n"
    REPORT+="**Overview:** $total total plans — $active_count active, $done_count done, $blocked_count blocked, $abandoned_count abandoned\n"
    REPORT+="\n"

    if [[ $active_count -gt 0 ]]; then
        REPORT+="### Active Plans\n"
        for f in "$PLAN_DIR"/*.md; do
            base=$(basename "$f")
            if [[ ! "$base" =~ -DONE\.md$ ]] && [[ ! "$base" =~ -BLOCKED\.md$ ]] && [[ ! "$base" =~ -ABANDONED\.md$ ]]; then
                name="${base%.md}"
                REPORT+="- $name\n"
            fi
        done
        REPORT+="\n"
    fi

    if [[ $done_count -gt 0 ]]; then
        REPORT+="### Recently Completed\n"
        # Collect completed plans and sort by completion date
        completed_entries=()
        for f in "$PLAN_DIR"/*-DONE.md; do
            name=$(basename "$f" .md)
            cdate=$(grep -i "Completion Date:" "$f" 2>/dev/null | head -1 | sed 's/.*Completion Date:\*\{0,2\} *//') || true
            cby=$(grep -i "Completed By:" "$f" 2>/dev/null | head -1 | sed 's/.*Completed By: //') || true
            sort_key="${cdate:-9999-99-99}"
            if [[ -n "$cdate" ]]; then
                completed_entries+=("$sort_key|$name (by ${cby:-unknown} on $cdate)")
            else
                completed_entries+=("$sort_key|$name")
            fi
        done
        # Sort by date descending and show last 5
        IFS=$'\n' sorted=($(sort -r <<<"${completed_entries[*]}"))
        unset IFS
        for entry in "${sorted[@]:0:5}"; do
            REPORT+="- ${entry#*|}\n"
        done
        REPORT+="\n"
    fi
else
    # Standard format
    REPORT+="============================================\n"
    REPORT+="  PLAN TRACKING — COMPREHENSIVE REPORT\n"
    REPORT+="  Generated: $(date "+%Y-%m-%d %H:%M")\n"
    REPORT+="============================================\n"
    REPORT+="\n"
    REPORT+="  Location: $PLAN_DIR\n"
    REPORT+="\n"
    REPORT+="  ┌─────────────────────┬──────┐\n"
    REPORT+="  │ Status              │ Count│\n"
    REPORT+="  ├─────────────────────┼──────┤\n"
    printf -v line "  │ %-19s │ %4d │\n" "Total" "$total"
    REPORT+="$line"
    printf -v line "  │ %-19s │ %4d │\n" "Active" "$active_count"
    REPORT+="$line"
    printf -v line "  │ %-19s │ %4d │\n" "Completed (DONE)" "$done_count"
    REPORT+="$line"
    printf -v line "  │ %-19s │ %4d │\n" "Blocked" "$blocked_count"
    REPORT+="$line"
    printf -v line "  │ %-19s │ %4d │\n" "Abandoned" "$abandoned_count"
    REPORT+="$line"
    REPORT+="  └─────────────────────┴──────┘\n"
    REPORT+="\n"

    # Active plans detail
    if [[ $active_count -gt 0 ]]; then
        REPORT+="--- ACTIVE PLANS ---\n"
        for f in "$PLAN_DIR"/*.md; do
            base=$(basename "$f")
            if [[ ! "$base" =~ -DONE\.md$ ]] && [[ ! "$base" =~ -BLOCKED\.md$ ]] && [[ ! "$base" =~ -ABANDONED\.md$ ]]; then
                name="${base%.md}"
                desc=$(awk '/^#/{found=1; next} found && NF{print; exit}' "$f" 2>/dev/null || echo "")
                if [[ -n "$desc" ]]; then
                    REPORT+="  📋 $name\n     $desc\n"
                else
                    REPORT+="  📋 $name\n"
                fi
            fi
        done
        REPORT+="\n"
    fi

    # Done plans detail
    if [[ $done_count -gt 0 ]]; then
        REPORT+="--- COMPLETED PLANS ---\n"
        for f in "$PLAN_DIR"/*-DONE.md; do
            name=$(basename "$f" .md)
            cdate=$(grep -i "Completion Date:" "$f" 2>/dev/null | head -1 | sed 's/.*Completion Date:\*\{0,2\} *//') || true
            cby=$(grep -i "Completed By:" "$f" 2>/dev/null | head -1 | sed 's/.*Completed By:\*\{0,2\} *//') || true
            REPORT+="  ✅ $name"
            [[ -n "$cdate" ]] && REPORT+=" (completed $cdate"
            [[ -n "$cby" ]] && REPORT+=" by $cby"
            [[ -n "$cdate" || -n "$cby" ]] && REPORT+=")"
            REPORT+="\n"
        done
        REPORT+="\n"
    fi

    # Blocked plans
    if [[ $blocked_count -gt 0 ]]; then
        REPORT+="--- BLOCKED PLANS ---\n"
        for f in "$PLAN_DIR"/*-BLOCKED.md; do
            name=$(basename "$f" .md)
            reason=$(grep -i "Reason:" "$f" 2>/dev/null | head -1 | sed 's/.*Reason: //') || true
            REPORT+="  🔒 $name"
            [[ -n "$reason" ]] && REPORT+=" — $reason"
            REPORT+="\n"
        done
        REPORT+="\n"
    fi

    # Abandoned plans
    if [[ $abandoned_count -gt 0 ]]; then
        REPORT+="--- ABANDONED PLANS ---\n"
        for f in "$PLAN_DIR"/*-ABANDONED.md; do
            name=$(basename "$f" .md)
            reason=$(grep -i "Reason" "$f" 2>/dev/null | head -1 | sed 's/.*Reason: //') || true
            REPORT+="  🗑️ $name"
            [[ -n "$reason" ]] && REPORT+=" — $reason"
            REPORT+="\n"
        done
        REPORT+="\n"
    fi

    REPORT+="============================================\n"
    REPORT+="  End of Report\n"
    REPORT+="============================================\n"
fi

if [[ -n "$OUTPUT_FILE" ]]; then
    echo -e "$REPORT" > "$OUTPUT_FILE"
    echo "Report written to: $OUTPUT_FILE"
else
    echo -e "$REPORT"
fi
