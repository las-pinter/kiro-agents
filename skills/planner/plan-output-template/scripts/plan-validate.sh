#!/usr/bin/env bash
# plan-validate.sh - Validate plan structure and quality against template
# Part of the plan-output-template skill
#
# Usage:
#   plan-validate.sh <plan.md>              - Validate a specific plan file
#   plan-validate.sh --dir <path>           - Validate all plans in a directory
#   plan-validate.sh --format detailed      - Show detailed results per check
#   plan-validate.sh --quiet                - Exit code only, no output
#   plan-validate.sh --help                 - Show this help
#
# Exit codes:
#   0 - All checks passed
#   1 - One or more checks failed

set -euo pipefail

# Defaults
FORMAT="normal"
QUIET=false
TARGET=""
TARGET_IS_DIR=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dir)
            TARGET="$2"
            TARGET_IS_DIR=true
            shift 2
            ;;
        --format)
            FORMAT="$2"
            shift 2
            ;;
        --quiet)
            QUIET=true
            shift
            ;;
        --help|-h)
            grep "^#" "$0" | grep -v "^#!/" | sed 's/^# //' | sed 's/^#//'
            exit 0
            ;;
        *)
            if [[ -z "$TARGET" ]]; then
                TARGET="$1"
                shift
            else
                echo "ERROR: Unknown argument: $1"
                echo "Use --help for usage info"
                exit 1
            fi
            ;;
    esac
done

# Collect files to validate
FILES=()

if $TARGET_IS_DIR; then
    if [[ ! -d "$TARGET" ]]; then
        echo "ERROR: Directory not found: $TARGET"
        exit 1
    fi
    shopt -s nullglob
    for f in "$TARGET"/*.md; do
        FILES+=("$f")
    done
elif [[ -n "$TARGET" ]]; then
    if [[ ! -f "$TARGET" ]]; then
        echo "ERROR: File not found: $TARGET"
        exit 1
    fi
    FILES+=("$TARGET")
else
    echo "ERROR: No plan file or directory specified."
    echo "Usage: plan-validate.sh <plan.md> [options]"
    echo "       plan-validate.sh --dir <path> [options]"
    exit 1
fi

if [[ ${#FILES[@]} -eq 0 ]]; then
    echo "No plan files found to validate."
    exit 0
fi

# Validation functions

check_section_exists() {
    local file="$1"
    local section_pattern="$2"
    if grep -qiE "$section_pattern" "$file" 2>/dev/null; then
        return 0
    fi
    return 1
}

count_tasks() {
    local file="$1"
    # Count lines matching Task patterns
    local task_lines
    task_lines=$(grep -ciE '^### Task [0-9]+:|^\| *[0-9]+ *\|' "$file" 2>/dev/null || true)
    task_lines=${task_lines:-0}
    echo "$task_lines"
}

check_acceptance_criteria() {
    local file="$1"
    # Count tasks that have acceptance-like keywords nearby
    local criteria_count

    # Look for "Acceptance" or "Acceptance Criteria" markers
    criteria_count=$(grep -ciE 'Acceptance:|Acceptance Criteria|Acceptance$' "$file" 2>/dev/null || true)
    echo "$criteria_count"
}

check_complexity_estimates() {
    local file="$1"
    # Count occurrences of complexity labels
    local complexity_count
    complexity_count=$(grep -ciE 'small|medium|large|<complexity>' "$file" 2>/dev/null || true)
    echo "$complexity_count"
}

check_date_prefix() {
    local basename="$1"
    if echo "$basename" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}-'; then
        return 0
    fi
    return 1
}

check_risks_section() {
    local file="$1"
    if check_section_exists "$file" '^## Risks|^## Risks &|Risk/Dependency|Risk \| Type'; then
        return 0
    fi
    return 1
}

check_open_questions() {
    local file="$1"
    if check_section_exists "$file" '^## Open Questions|Open Questions|-\s*\[ \]'; then
        return 0
    fi
    return 1
}

check_circular_dependencies() {
    local file="$1"
    # Simple check: look for patterns like "Task 1" depending on "Task 2" where
    # "Task 2" depends on "Task 1" — this is a basic circular dependency scan
    # Extract all dependency references
    local deps
    deps=$(grep -oE 'Task [0-9]+' "$file" 2>/dev/null | sort -u || true)
    if [[ -z "$deps" ]]; then
        return 0  # No tasks found = no circular deps
    fi
    # Check for obvious circular patterns in the text
    if grep -qiE '(depends on|depends upon).*(itself|circular|cycle)' "$file" 2>/dev/null; then
        return 1
    fi
    return 0
}

check_acceptance_quality() {
    local file="$1"
    # Check for weak acceptance criteria that should be rejected
    local weak_count
    weak_count=$(grep -ciE '"works correctly"|"done properly"|"looks good"|"should work"|"as expected"' "$file" 2>/dev/null || true)
    if [[ "$weak_count" -gt 0 ]]; then
        return 1
    fi
    return 0
}

check_high_impact_risks_flagged() {
    local file="$1"
    # Check if high-impact risks have mitigations
    local high_risks
    high_risks=$(grep -ciE 'high.*impact|high.*risk|critical' "$file" 2>/dev/null || true)
    local mitigations
    mitigations=$(grep -ciE 'mitigation|Mitigation|workaround|fallback|retry|redundancy' "$file" 2>/dev/null || true)
    if [[ "$high_risks" -gt 0 && "$mitigations" -eq 0 ]]; then
        return 1
    fi
    return 0
}

# Run validation on each file
OVERALL_EXIT=0

for plan_file in "${FILES[@]}"; do
    ISSUES=0
    WARNINGS=0
    PASSED=0

    plan_basename=$(basename "$plan_file")
    plan_name="${plan_basename%.md}"

    if ! $QUIET; then
        echo "============================================"
        echo "  PLAN VALIDATION: $plan_basename"
        echo "============================================"
    fi

    # Check 1: File exists and is non-empty
    if [[ -s "$plan_file" ]]; then
        PASSED=$((PASSED + 1))
        ! $QUIET && echo "  ✅ File exists and is non-empty."
    else
        ISSUES=$((ISSUES + 1))
        ! $QUIET && echo "  ❌ File is empty or missing!"
    fi

    # Check 2: Has a level-1 heading (title)
    if head -10 "$plan_file" | grep -qE '^# '; then
        PASSED=$((PASSED + 1))
        ! $QUIET && echo "  ✅ Has a title (level-1 heading)."
    else
        ISSUES=$((ISSUES + 1))
        ! $QUIET && echo "  ❌ Missing title — plan must start with a level-1 heading."
    fi

    # Check 3: Date prefix in filename
    if check_date_prefix "$plan_basename"; then
        PASSED=$((PASSED + 1))
        ! $QUIET && echo "  ✅ Filename has date prefix (YYYY-MM-DD-)."
    else
        WARNINGS=$((WARNINGS + 1))
        ! $QUIET && echo "  ⚠️  Filename missing date prefix (YYYY-MM-DD-) — plan-tracking requires it."
    fi

    # Check 4: Objective section (or Goal/Description)
    if check_section_exists "$plan_file" '^## (Objective|Goal|Description|Bug Description|Objective|What)' ; then
        PASSED=$((PASSED + 1))
        ! $QUIET && echo "  ✅ Has objective/goal section."
    else
        ISSUES=$((ISSUES + 1))
        ! $QUIET && echo "  ❌ Missing objective/goal section — plan needs a clear WHAT and WHY."
    fi

    # Check 5: Has tasks
    task_count=$(count_tasks "$plan_file")
    if [[ "$task_count" -gt 0 ]]; then
        PASSED=$((PASSED + 1))
        ! $QUIET && echo "  ✅ Has tasks (${task_count} task references found)."
    else
        ISSUES=$((ISSUES + 1))
        ! $QUIET && echo "  ❌ No tasks found — plan must contain at least one task."
    fi

    # Check 6: Tasks have acceptance criteria
    criteria_count=$(check_acceptance_criteria "$plan_file")
    if [[ "$criteria_count" -gt 0 ]]; then
        PASSED=$((PASSED + 1))
        ! $QUIET && echo "  ✅ Acceptance criteria found (${criteria_count} references)."
    else
        ISSUES=$((ISSUES + 1))
        ! $QUIET && echo "  ❌ No acceptance criteria found — every task needs verifiable acceptance criteria."
    fi

    # Check 7: Tasks have complexity estimates
    complexity_count=$(check_complexity_estimates "$plan_file")
    if [[ "$complexity_count" -gt 0 ]]; then
        PASSED=$((PASSED + 1))
        ! $QUIET && echo "  ✅ Complexity estimates found (${complexity_count} references)."
    else
        WARNINGS=$((WARNINGS + 1))
        ! $QUIET && echo "  ⚠️  No complexity estimates found — tasks should have small/medium/large labels."
    fi

    # Check 8: Dependencies section or dependency references
    if check_section_exists "$plan_file" 'Depend|depends on|Depends On'; then
        PASSED=$((PASSED + 1))
        ! $QUIET && echo "  ✅ Dependencies mapped."
    else
        WARNINGS=$((WARNINGS + 1))
        ! $QUIET && echo "  ⚠️  No dependency mappings found — tasks may be missing dependency information."
    fi

    # Check 9: No circular dependencies
    if check_circular_dependencies "$plan_file"; then
        PASSED=$((PASSED + 1))
        ! $QUIET && echo "  ✅ No circular dependencies detected."
    else
        ISSUES=$((ISSUES + 1))
        ! $QUIET && echo "  ❌ Circular dependencies detected — tasks need restructuring."
    fi

    # Check 10: Risks section
    if check_risks_section "$plan_file"; then
        PASSED=$((PASSED + 1))
        ! $QUIET && echo "  ✅ Risks section present."
    else
        WARNINGS=$((WARNINGS + 1))
        ! $QUIET && echo "  ⚠️  No risks section found — even 'None identified' should be explicit."
    fi

    # Check 11: Open questions section
    if check_open_questions "$plan_file"; then
        PASSED=$((PASSED + 1))
        ! $QUIET && echo "  ✅ Open questions section present."
    else
        WARNINGS=$((WARNINGS + 1))
        ! $QUIET && echo "  ⚠️  No open questions section — add one even if empty."
    fi

    # Check 12: Acceptance criteria quality (no weak language)
    if check_acceptance_quality "$plan_file"; then
        PASSED=$((PASSED + 1))
        ! $QUIET && echo "  ✅ Acceptance criteria are verifiable (no weak language detected)."
    else
        ISSUES=$((ISSUES + 1))
        ! $QUIET && echo "  ❌ Weak acceptance criteria detected ('works correctly', 'done properly', etc.) — must be verifiable."
    fi

    # Check 13: High-impact risks have mitigations
    if check_high_impact_risks_flagged "$plan_file"; then
        PASSED=$((PASSED + 1))
        ! $QUIET && echo "  ✅ High-impact risks have mitigations."
    else
        WARNINGS=$((WARNINGS + 1))
        ! $QUIET && echo "  ⚠️  High-impact risks found without mitigations — flag for human review."
    fi

    # Summary
    TOTAL_CHECKS=13
    if ! $QUIET; then
        echo ""
        echo "  ┌──────────────────────────────────────────┐"
        echo "  │  RESULTS: $PASSED/$TOTAL_CHECKS checks passed"
        if [[ "$ISSUES" -gt 0 ]]; then
            echo "  │  ❌ $ISSUES issue(s) — MUST fix before handoff"
        else
            echo "  │  ✅ No issues found"
        fi
        if [[ "$WARNINGS" -gt 0 ]]; then
            echo "  │  ⚠️  $WARNINGS warning(s) — review recommended"
        fi
        echo "  └──────────────────────────────────────────┘"
        echo ""
    fi

    if [[ "$ISSUES" -gt 0 ]]; then
        OVERALL_EXIT=1
    fi
done

exit $OVERALL_EXIT
