#!/usr/bin/env bash
# plan-list.sh - List plans by status with details
# Part of the plan-tracking skill
#
# Usage:
#   plan-list.sh                    - List all plans (default)
#   plan-list.sh --status done      - List only completed plans
#   plan-list.sh --status active    - List only active/in-progress plans
#   plan-list.sh --status blocked   - List only blocked plans
#   plan-list.sh --status abandoned - List only abandoned plans
#   plan-list.sh --status all       - List ALL plans with status indicators
#   plan-list.sh --dir <path>       - Specify plan directory
#   plan-list.sh --format short     - Compact output (default)
#   plan-list.sh --format detailed  - Show more details per plan
#   plan-list.sh --help             - Show this help

set -euo pipefail

PLAN_DIR="${HOME}/agent-notes/planner/plans"
STATUS="all"
FORMAT="short"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --status)
            STATUS="$2"
            shift 2
            ;;
        --dir)
            PLAN_DIR="$2"
            shift 2
            ;;
        --format)
            FORMAT="$2"
            shift 2
            ;;
        --help|-h)
            grep "^#" "$0" | grep -v "^#!/" | sed 's/^# //' | sed 's/^#//'
            exit 0
            ;;
        *)
            echo "UNKNOWN OPTION: $1"
            echo "Use --help for usage info"
            exit 1
            ;;
    esac
done

if [[ ! -d "$PLAN_DIR" ]]; then
    echo "ERROR: Plan directory not found: $PLAN_DIR"
    echo "Create it with: mkdir -p \"$PLAN_DIR\""
    exit 1
fi

# Determine which files to list
case "$STATUS" in
    done)
        PATTERN="*-DONE.md"
        STATUS_LABEL="DONE"
        ;;
    blocked)
        PATTERN="*-BLOCKED.md"
        STATUS_LABEL="BLOCKED"
        ;;
    abandoned)
        PATTERN="*-ABANDONED.md"
        STATUS_LABEL="ABANDONED"
        ;;
    active)
        # Active = .md files that DON'T have status suffixes
        STATUS_LABEL="ACTIVE"
        ;;
    all|*)
        PATTERN="*.md"
        STATUS_LABEL="ALL"
        ;;
esac

echo "============================================"
echo "  PLAN TRACKING REPORT — STATUS: $STATUS_LABEL"
echo "============================================"

if [[ "$STATUS" == "active" ]]; then
    # List active plans (no status suffix)
    shopt -s nullglob
    files=()
    for f in "$PLAN_DIR"/*.md; do
        base=$(basename "$f")
        if [[ ! "$base" =~ -DONE\.md$ ]] && [[ ! "$base" =~ -BLOCKED\.md$ ]] && [[ ! "$base" =~ -ABANDONED\.md$ ]]; then
            files+=("$f")
        fi
    done

    if [[ ${#files[@]} -eq 0 ]]; then
        echo "  No active plans found."
        echo ""
        exit 0
    fi

    if [[ "$FORMAT" == "detailed" ]]; then
        for f in "${files[@]}"; do
            base=$(basename "$f" .md)
            echo "  📋 [ACTIVE]  $base"
            echo "     Location: $f"
            # Extract first non-empty line after # heading as description
            desc=$(awk '/^#/{found=1; next} found && NF{print; exit}' "$f" 2>/dev/null || echo "No description")
            echo "     Summary:  ${desc:0:100}"
            echo ""
        done
    else
        for f in "${files[@]}"; do
            base=$(basename "$f" .md)
            echo "  📋 [ACTIVE]  $base"
        done
    fi

elif [[ "$STATUS" == "all" ]]; then
    # Show all plans grouped by status
    shopt -s nullglob

    # Active
    echo ""
    echo "--- ACTIVE PLANS ---"
    count=0
    for f in "$PLAN_DIR"/*.md; do
        base=$(basename "$f")
        if [[ ! "$base" =~ -DONE\.md$ ]] && [[ ! "$base" =~ -BLOCKED\.md$ ]] && [[ ! "$base" =~ -ABANDONED\.md$ ]]; then
            echo "  📋  $(basename "$f" .md)"
            count=$((count + 1))
        fi
    done
    [[ $count -eq 0 ]] && echo "  (none)"
    echo ""

    # Done
    echo "--- COMPLETED PLANS ---"
    count=0
    for f in "$PLAN_DIR"/*-DONE.md; do
        echo "  ✅  $(basename "$f" .md)"
        count=$((count + 1))
    done
    [[ $count -eq 0 ]] && echo "  (none)"
    echo ""

    # Blocked
    echo "--- BLOCKED PLANS ---"
    count=0
    for f in "$PLAN_DIR"/*-BLOCKED.md; do
        echo "  🔒  $(basename "$f" .md)"
        count=$((count + 1))
    done
    [[ $count -eq 0 ]] && echo "  (none)"
    echo ""

    # Abandoned
    echo "--- ABANDONED PLANS ---"
    count=0
    for f in "$PLAN_DIR"/*-ABANDONED.md; do
        echo "  🗑️  $(basename "$f" .md)"
        count=$((count + 1))
    done
    [[ $count -eq 0 ]] && echo "  (none)"
    echo ""

else
    # Specific status
    shopt -s nullglob
    files=("$PLAN_DIR"/$PATTERN)

    if [[ ${#files[@]} -eq 0 ]]; then
        echo "  No plans found with status: $STATUS_LABEL"
        echo ""
        exit 0
    fi

    if [[ "$FORMAT" == "detailed" ]]; then
        for f in "${files[@]}"; do
            echo "  $(basename "$f")"
            echo "     Path: $f"
            # Check for completion metadata
            if grep -q "COMPLETED\|PLAN COMPLETED\|Plan Completed" "$f" 2>/dev/null; then
                echo "     Status: ✅ COMPLETE (has completion metadata)"
            fi
            # Extract completion date if present
            cdate=$(grep -i "Completion Date:" "$f" 2>/dev/null | head -1 | sed 's/.*Completion Date:\*\{0,2\} *//') || true
            [[ -n "$cdate" ]] && echo "     Completed: $cdate"
            cby=$(grep -i "Completed By:" "$f" 2>/dev/null | head -1 | sed 's/.*Completed By:\*\{0,2\} *//') || true
            [[ -n "$cby" ]] && echo "     By: $cby"
            echo ""
        done
    else
        for f in "${files[@]}"; do
            echo "  $(basename "$f")"
        done
    fi
fi

# Summary - always show overall totals
echo "============================================"
active_count=0
done_count=0
blocked_count=0
abandoned_count=0

shopt -s nullglob
all_plans=("$PLAN_DIR"/*.md)
for f in "${all_plans[@]}"; do
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
total=${#all_plans[@]}

echo "  Overall totals: $total total | $active_count active | $done_count done | $blocked_count blocked | $abandoned_count abandoned"
echo "============================================"
echo ""
