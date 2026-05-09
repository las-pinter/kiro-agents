#!/usr/bin/env bash
# plan-mark.sh - Mark plans as done/blocked/abandoned with metadata
# Part of the plan-tracking skill
#
# Usage:
#   plan-mark.sh <plan-file> --status done [options]
#   plan-mark.sh <plan-file> --status blocked [options]
#   plan-mark.sh <plan-file> --status abandoned [options]
#
# Arguments:
#   <plan-file>  - Path to the plan file (can be relative to plan dir)
#
# Options:
#   --status <done|blocked|abandoned>  - New status for the plan (REQUIRED)
#   --commits "hash1 - msg1 | hash2 - msg2"  - Commit IDs and messages
#   --by "Agent Name, Role"           - Who completed the work
#   --results "Summary of results"    - What was achieved
#   --reason "Why abandoned/blocked"  - Reason (for blocked/abandoned)
#   --dir <path>                      - Plan directory (default: ~/agent-notes/planner/plans)
#   --dry-run                         - Show what would be done without doing it
#   --help                            - Show this help

set -euo pipefail

PLAN_DIR="${HOME}/agent-notes/planner/plans"
STATUS=""
COMMITS=""
COMPLETED_BY=""
RESULTS=""
REASON=""
DRY_RUN=false

# Parse arguments
POSITIONAL=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --status)
            STATUS="$2"
            shift 2
            ;;
        --commits)
            COMMITS="$2"
            shift 2
            ;;
        --by)
            COMPLETED_BY="$2"
            shift 2
            ;;
        --results)
            RESULTS="$2"
            shift 2
            ;;
        --reason)
            REASON="$2"
            shift 2
            ;;
        --dir)
            PLAN_DIR="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            grep "^#" "$0" | grep -v "^#!/" | sed 's/^# //' | sed 's/^#//'
            exit 0
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

# Restore positional arguments
set -- "${POSITIONAL[@]}"
PLAN_FILE="${1:-}"

# Validate
if [[ -z "$PLAN_FILE" ]]; then
    echo "ERROR: No plan file specified!"
    echo "Usage: plan-mark.sh <plan-file> --status <done|blocked|abandoned>"
    exit 1
fi

if [[ -z "$STATUS" ]]; then
    echo "ERROR: No status specified! Use --status <done|blocked|abandoned>"
    exit 1
fi

case "$STATUS" in
    done|blocked|abandoned) ;;
    *)
        echo "ERROR: Invalid status '$STATUS'. Must be: done, blocked, or abandoned"
        exit 1
        ;;
esac

# Resolve plan file path
if [[ -f "$PLAN_FILE" ]]; then
    PLAN_PATH="$PLAN_FILE"
elif [[ -f "${PLAN_DIR}/${PLAN_FILE}" ]]; then
    PLAN_PATH="${PLAN_DIR}/${PLAN_FILE}"
elif [[ -f "${PLAN_DIR}/${PLAN_FILE}.md" ]]; then
    PLAN_PATH="${PLAN_DIR}/${PLAN_FILE}.md"
else
    echo "ERROR: Plan file not found!"
    echo "  Tried: $PLAN_FILE"
    echo "  Tried: ${PLAN_DIR}/${PLAN_FILE}"
    echo "  Tried: ${PLAN_DIR}/${PLAN_FILE}.md"
    echo ""
    echo "Use plan-list.sh to see available plans."
    exit 1
fi

PLAN_BASE=$(basename "$PLAN_PATH")
PLAN_DIRNAME=$(dirname "$PLAN_PATH")
PLAN_NAME="${PLAN_BASE%.md}"

# Check if already has a status suffix
if echo "$PLAN_NAME" | grep -qE '\-(DONE|BLOCKED|ABANDONED)$'; then
    echo "WARNING: Plan '$PLAN_BASE' already has a status suffix!"
    echo "  Current status: $(echo "$PLAN_NAME" | grep -oE '\-(DONE|BLOCKED|ABANDONED)$' | sed 's/^-//')"
    echo "  To change status, manually revert the suffix first, then re-run this command."
    exit 1
fi

# Determine new filename
NEW_PLAN_NAME="${PLAN_NAME}-${STATUS^^}"
NEW_PLAN_PATH="${PLAN_DIRNAME}/${NEW_PLAN_NAME}.md"

if [[ -f "$NEW_PLAN_PATH" ]]; then
    echo "ERROR: Target file already exists: $NEW_PLAN_PATH"
    exit 1
fi

# Show what we're gonna do
echo "============================================"
echo "  PLAN MARK — Setting status to: ${STATUS^^}"
echo "============================================"
echo "  Source: $PLAN_PATH"
echo "  Target: $NEW_PLAN_PATH"
echo ""

# Build metadata section
METADATA=""

case "$STATUS" in
    done)
        METADATA+=$'\n---\n'
        METADATA+=$'\n## ✅ PLAN COMPLETED'
        METADATA+=$'\n'
        METADATA+=$'\n**Completion Date:** '$(date +%Y-%m-%d)
        [[ -n "$COMPLETED_BY" ]] && METADATA+=$'\n**Completed By:** '"$COMPLETED_BY"
        if [[ -n "$COMMITS" ]]; then
            METADATA+=$'\n**Commit ID(s):**'
            IFS='|' read -ra COMMIT_LIST <<< "$COMMITS"
            for commit in "${COMMIT_LIST[@]}"; do
                commit=$(echo "$commit" | xargs)
                METADATA+=$'\n'"- $commit"
            done
        fi
        METADATA+=$'\n'
        METADATA+=$'\n**What Was Done:**'
        [[ -n "$RESULTS" ]] && METADATA+=$'\n- '"$RESULTS" || METADATA+=$'\n- (Summary pending)'
        METADATA+=$'\n'
        METADATA+=$'\n**Result:** Plan fully executed and objectives met.'
        ;;
    blocked)
        METADATA+=$'\n---'
        METADATA+=$'\n## 🔒 PLAN BLOCKED'
        METADATA+=$'\n'
        METADATA+=$'\n**Date Blocked:** '$(date +%Y-%m-%d)
        [[ -n "$COMPLETED_BY" ]] && METADATA+=$'\n**Identified By:** '"$COMPLETED_BY"
        METADATA+=$'\n'
        METADATA+=$'\n**Reason:**'
        [[ -n "$REASON" ]] && METADATA+=$'\n'"$REASON" || METADATA+=$'\n- (No reason specified)'
        METADATA+=$'\n'
        METADATA+=$'\n**Blocking Dependencies:**'
        METADATA+=$'\n- (List what is needed to unblock)'
        ;;
    abandoned)
        METADATA+=$'\n---'
        METADATA+=$'\n## 🗑️ PLAN ABANDONED'
        METADATA+=$'\n'
        METADATA+=$'\n**Abandonment Date:** '$(date +%Y-%m-%d)
        [[ -n "$COMPLETED_BY" ]] && METADATA+=$'\n**Decision By:** '"$COMPLETED_BY"
        METADATA+=$'\n'
        METADATA+=$'\n**Reason for Abandonment:**'
        [[ -n "$REASON" ]] && METADATA+=$'\n'"$REASON" || METADATA+=$'\n- (No reason specified)'
        METADATA+=$'\n'
        METADATA+=$'\n**Replacement Plan(s):**'
        METADATA+=$'\n- (List if applicable)'
        ;;
esac

METADATA+=$'\n'

if $DRY_RUN; then
    echo "  [DRY RUN] Would rename: $(basename "$PLAN_PATH") → $(basename "$NEW_PLAN_PATH")"
    echo "  [DRY RUN] Would append metadata:"
    echo "$METADATA"
    echo ""
    echo "  Dry run complete. No changes made."
    exit 0
fi

# Do the rename
mv "$PLAN_PATH" "$NEW_PLAN_PATH"
echo "  ✅ Renamed: $(basename "$PLAN_PATH") → $(basename "$NEW_PLAN_PATH")"

# Append metadata
echo "$METADATA" >> "$NEW_PLAN_PATH"
echo "  ✅ Metadata appended."

# Verify
if [[ -f "$NEW_PLAN_PATH" ]]; then
    echo "  ✅ Verified: $NEW_PLAN_PATH exists."
fi

echo ""
echo "  Plan successfully marked as ${STATUS^^}!"
echo "============================================"
echo ""

if [[ "$STATUS" == "done" ]]; then
    echo "  NEXT STEPS:"
    echo "  1. Reference this plan in your daily journal"
    echo "  2. Run: plan-list.sh --status done  (to see all completed plans)"
    echo ""
fi
