#!/usr/bin/env bash
# plan-verify.sh - Verify plan structure and check commit references
# Part of the plan-tracking skill
#
# Usage:
#   plan-verify.sh                   - Verify all plans in default directory
#   plan-verify.sh <plan-file>       - Verify a specific plan
#   plan-verify.sh --dir <path>      - Check plans in a specific directory
#   plan-verify.sh --fix             - Attempt to fix common issues
#   plan-verify.sh --help            - Show this help

set -euo pipefail

PLAN_DIR="${HOME}/agent-notes/planner/plans"
SPECIFIC_FILE=""
FIX_MODE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dir)
            PLAN_DIR="$2"
            shift 2
            ;;
        --fix)
            FIX_MODE=true
            shift
            ;;
        --help|-h)
            grep "^#" "$0" | grep -v "^#!/" | sed 's/^# //' | sed 's/^#//'
            exit 0
            ;;
        *)
            SPECIFIC_FILE="$1"
            shift
            ;;
    esac
done

if [[ ! -d "$PLAN_DIR" ]]; then
    echo "ERROR: Plan directory not found: $PLAN_DIR"
    exit 1
fi

echo "============================================"
echo "  PLAN VERIFICATION REPORT"
echo "============================================"

TOTAL_ISSUES=0
CHECKED=0

verify_plan() {
    local file="$1"
    local basename=$(basename "$file")
    local issues=0
    local warnings=0

    echo ""
    echo "--- Checking: $basename ---"

    # Check 1: File exists and is readable
    if [[ ! -f "$file" ]]; then
        echo "  ❌ ERROR: File does not exist or is not readable."
        TOTAL_ISSUES=$((TOTAL_ISSUES + 1))
        return
    fi

    # Check 2: File has content (not empty)
    if [[ ! -s "$file" ]]; then
        echo "  ❌ ERROR: File is empty!"
        issues=$((issues + 1))
    fi

    # Check 3: File starts with a heading
    if head -1 "$file" | grep -qE '^#'; then
        echo "  ✅ Has proper heading."
    else
        echo "  ⚠️  WARNING: File does not start with a markdown heading."
        warnings=$((warnings + 1))
    fi

    # Check 4: Proper filename format (YYYY-MM-DD-)
    if echo "$basename" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}-'; then
        echo "  ✅ Filename has date prefix."
    else
        echo "  ⚠️  WARNING: Filename missing date prefix (YYYY-MM-DD-)."
        warnings=$((warnings + 1))
    fi

    # Check 5: Status suffix consistency
    if echo "$basename" | grep -qE '\-(DONE|BLOCKED|ABANDONED)\.md$'; then
        local status=$(echo "$basename" | grep -oE '\-(DONE|BLOCKED|ABANDONED)\.md$' | sed 's/-//; s/\.md$//')
        echo "  ✅ Status: $status"

        # Check that completed plans have metadata
        if [[ "$status" == "DONE" ]]; then
            if grep -q "Completion Date:" "$file" 2>/dev/null; then
                echo "  ✅ Has completion date metadata."
            else
                echo "  ⚠️  WARNING: Marked DONE but missing 'Completion Date:' metadata."
                warnings=$((warnings + 1))
            fi
            if grep -q "Commit ID" "$file" 2>/dev/null; then
                echo "  ✅ Has commit ID references."
            fi
        fi

        if [[ "$status" == "BLOCKED" ]]; then
            if grep -q "Reason:" "$file" 2>/dev/null; then
                echo "  ✅ Has blocking reason."
            else
                echo "  ⚠️  WARNING: Marked BLOCKED but missing reason."
                warnings=$((warnings + 1))
            fi
        fi

        if [[ "$status" == "ABANDONED" ]]; then
            if grep -q "Reason" "$file" 2>/dev/null; then
                echo "  ✅ Has abandonment reason."
            else
                echo "  ⚠️  WARNING: Marked ABANDONED but missing reason."
                warnings=$((warnings + 1))
            fi
        fi
    else
        echo "  📋 Status: Active (no status suffix)"
    fi

    # Check 6: Verify commit references (if any)
    commit_refs=$(grep -oE '[0-9a-f]{7,40}' "$file" 2>/dev/null || true)
    if [[ -n "$commit_refs" ]]; then
        echo "  🔍 Checking commit references..."
        # Try to find a git repo to check against
        git_repo=""
        for possible_repo in "$PLAN_DIR/../../.." "$HOME/persona-agents" "$HOME" "$(pwd)"; do
            if git -C "$possible_repo" rev-parse --git-dir &>/dev/null 2>&1; then
                git_repo="$possible_repo"
                break
            fi
        done

        if [[ -n "$git_repo" ]]; then
            echo "     Using git repo: $git_repo"
            while IFS= read -r ref; do
                ref=$(echo "$ref" | xargs)
                [[ -z "$ref" ]] && continue
                # Skip numbers that are likely just numbers, not commit hashes
                [[ ${#ref} -lt 7 ]] && continue
                if git -C "$git_repo" cat-file -e "$ref" 2>/dev/null; then
                    echo "     ✅ Commit $ref — found in git history."
                else
                    echo "     ⚠️  WARNING: Commit $ref — NOT found in git history!"
                    warnings=$((warnings + 1))
                fi
            done <<< "$commit_refs"
        else
            echo "     ⚠️  No git repo found for commit verification (skipping)."
        fi
    fi

    # Report
    if [[ $issues -eq 0 && $warnings -eq 0 ]]; then
        echo "  ✅ ALL CHECKS PASSED"
    else
        echo "  📊 Results: $issues issue(s), $warnings warning(s)"
    fi

    CHECKED=$((CHECKED + 1))
    TOTAL_ISSUES=$((TOTAL_ISSUES + issues + warnings))

    # Auto-fix if requested
    if $FIX_MODE && [[ $warnings -gt 0 ]]; then
        echo "  🔧 Attempting fixes..."
        local fixed_any=false

        # Fix: add completion date if missing for DONE plans
        if echo "$basename" | grep -qE '\-DONE\.md$' && ! grep -q "Completion Date:" "$file" 2>/dev/null; then
            echo "     Adding missing completion date..."
            {
                echo ""
                echo "---"
                echo ""
                echo "**Completion Date:** $(date +%Y-%m-%d)"
            } >> "$file"
            echo "     ✅ Added completion date."
            fixed_any=true
        fi

        # Fix: add blocking reason placeholder if missing for BLOCKED plans
        if echo "$basename" | grep -qE '\-BLOCKED\.md$'; then
            if ! grep -q "Reason:" "$file" 2>/dev/null; then
                echo "     Adding missing blocking reason..."
                {
                    echo ""
                    echo "---"
                    echo ""
                    echo "## \360\237\224\222 PLAN BLOCKED"
                    echo ""
                    echo "**Date Blocked:** $(date +%Y-%m-%d)"
                    echo ""
                    echo "**Reason:**"
                    echo "Blocked by external dependency — details pending."
                    echo ""
                    echo "**Blocking Dependencies:**"
                    echo "- (Identify what is needed to unblock)"
                } >> "$file"
                echo "     \342\234\205 Added blocking reason."
                fixed_any=true
            fi
        fi

        # Fix: add abandonment reason placeholder if missing for ABANDONED plans
        if echo "$basename" | grep -qE '\-ABANDONED\.md$'; then
            if ! grep -q "Reason" "$file" 2>/dev/null; then
                echo "     Adding missing abandonment reason..."
                {
                    echo ""
                    echo "---"
                    echo ""
                    echo "## \360\237\227\221\357\270\217 PLAN ABANDONED"
                    echo ""
                    echo "**Abandonment Date:** $(date +%Y-%m-%d)"
                    echo ""
                    echo "**Reason for Abandonment:**"
                    echo "Plan no longer relevant — details pending."
                    echo ""
                    echo "**Replacement Plan(s):**"
                    echo "- (List if applicable)"
                } >> "$file"
                echo "     \342\234\205 Added abandonment reason."
                fixed_any=true
            fi
        fi

        if ! $fixed_any; then
            echo "     No auto-fixable issues found. Manual review may be needed."
        fi
    fi
}

echo ""
echo "Directory: $PLAN_DIR"
echo ""

if [[ -n "$SPECIFIC_FILE" ]]; then
    if [[ -f "$SPECIFIC_FILE" ]]; then
        verify_plan "$SPECIFIC_FILE"
    elif [[ -f "${PLAN_DIR}/${SPECIFIC_FILE}" ]]; then
        verify_plan "${PLAN_DIR}/${SPECIFIC_FILE}"
    elif [[ -f "${PLAN_DIR}/${SPECIFIC_FILE}.md" ]]; then
        verify_plan "${PLAN_DIR}/${SPECIFIC_FILE}.md"
    else
        echo "ERROR: Plan file not found: $SPECIFIC_FILE"
        exit 1
    fi
else
    shopt -s nullglob
    for f in "$PLAN_DIR"/*.md; do
        verify_plan "$f"
    done
fi

echo ""
echo "============================================"
if [[ $TOTAL_ISSUES -eq 0 ]]; then
    echo "  ✅ ALL PLANS VERIFIED — $CHECKED file(s) checked, no issues found."
else
    echo "  ⚠️  $TOTAL_ISSUES issue(s) found across $CHECKED file(s)."
fi
echo "============================================"
echo ""
