#!/usr/bin/env bash
# plan-render.sh - Render plans in different output formats
# Part of the plan-output-template skill
#
# Usage:
#   plan-render.sh <plan.md>              - Full plan output (default)
#   plan-render.sh <plan.md> --summary    - Condensed overview
#   plan-render.sh <plan.md> --handoff    - Implementer-focused view
#   plan-render.sh <plan.md> --tracking   - Plan-tracking integration format
#   plan-render.sh --help                 - Show this help

set -euo pipefail

FORMAT="default"
PLAN_FILE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --summary|-s)
            FORMAT="summary"
            shift
            ;;
        --handoff|-h)
            FORMAT="handoff"
            shift
            ;;
        --tracking|-t)
            FORMAT="tracking"
            shift
            ;;
        --help)
            grep "^#" "$0" | grep -v "^#!/" | sed 's/^# //' | sed 's/^#//'
            exit 0
            ;;
        *)
            if [[ -z "$PLAN_FILE" ]]; then
                PLAN_FILE="$1"
                shift
            else
                echo "ERROR: Unknown argument: $1"
                echo "Use --help for usage info"
                exit 1
            fi
            ;;
    esac
done

if [[ -z "$PLAN_FILE" ]]; then
    echo "ERROR: No plan file specified."
    echo "Usage: plan-render.sh <plan.md> [--summary|--handoff|--tracking]"
    exit 1
fi

if [[ ! -f "$PLAN_FILE" ]]; then
    echo "ERROR: File not found: $PLAN_FILE"
    exit 1
fi

plan_basename=$(basename "$PLAN_FILE" .md)

# Extract sections for rendering
extract_title() {
    head -1 "$PLAN_FILE"
}

extract_objective() {
    # Extract content under ## Objective or ## Goal
    awk '/^## (Objective|Goal|Bug Description)/{found=1; next} /^## [A-Z]/{if(found) exit} found{print}' "$PLAN_FILE" 2>/dev/null || echo "(Objective not found)"
}

extract_tasks() {
    # Extract task sections (### Task or table rows)
    awk '/^### Task [0-9]+:/{found=1} found{print} /^## [A-Z]/{if(found && !/^## Tasks?/ && !/^## Tasks \&/) exit}' "$PLAN_FILE" 2>/dev/null
}

extract_risks() {
    awk '/^## Risks/{found=1; next} /^## [A-Z]/{if(found) exit} found{print}' "$PLAN_FILE" 2>/dev/null || echo "(No risks section)"
}

extract_open_questions() {
    awk '/^## Open Questions/{found=1; next} /^## [A-Z]/{if(found) exit} found{print}' "$PLAN_FILE" 2>/dev/null || echo "(No open questions section)"
}

count_tasks() {
    local count
    count=$(grep -cE '^### Task [0-9]+:' "$PLAN_FILE" 2>/dev/null || echo 0)
    echo "$count"
}

case "$FORMAT" in
    default)
        # Full plan — just output the file with a header
        echo "============================================"
        echo "  PLAN: $(extract_title | sed 's/^# //')"
        echo "  File: $plan_basename"
        echo "============================================"
        echo ""
        cat "$PLAN_FILE"
        ;;

    summary)
        # Condensed overview — one line per task, plus risks and questions
        title=$(extract_title | sed 's/^# //')
        echo "============================================"
        echo "  PLAN SUMMARY: $title"
        echo "============================================"
        echo ""
        echo "Objective:"
        extract_objective | head -5 | sed 's/^/  /'
        echo ""
        echo "Tasks ($(count_tasks) total):"
        # Extract each task line
        grep -n '^### Task [0-9]*:' "$PLAN_FILE" 2>/dev/null | while IFS=: read -r line_num task_line; do
            task_num=$(echo "$task_line" | grep -oE 'Task [0-9]+')
            task_name=$(echo "$task_line" | sed 's/^### //')
            deps=$(sed -n "$((line_num+1)),$((line_num+5))p" "$PLAN_FILE" | grep -i 'Depend' | head -1 || echo "  (no explicit deps)")
            echo "  • $task_name"
            echo "    $deps"
        done
        echo ""
        echo "Risks & Blockers:"
        extract_risks | head -10 | sed 's/^/  /'
        echo ""
        echo "Open Questions:"
        extract_open_questions | head -10 | sed 's/^/  /'
        ;;

    handoff)
        # Implementer-focused view — shows tasks in dependency order with
        # only the info the implementer needs
        title=$(extract_title | sed 's/^# //')
        echo "============================================"
        echo "  HANDOFF: $title"
        echo "  For: Implementer"
        echo "============================================"
        echo ""
        echo "Objective:"
        extract_objective | head -3 | sed 's/^/  /'
        echo ""
        echo "---"
        echo ""
        echo "EXECUTION ORDER (by dependency):"
        echo ""

        # Collect tasks with their dependency info
        # Parse ### Task N: Name (complexity) blocks
        current_task=""
        current_deps=""
        current_accept=""
        current_details=""
        in_task=false
        task_num=0

        while IFS= read -r line; do
            if echo "$line" | grep -qE '^### Task [0-9]+:'; then
                # Output previous task if any
                if $in_task && [[ -n "$current_task" ]]; then
                    echo "  ┌─────────────────────────────────────────┐"
                    echo "  │ TASK $task_num: $current_task"
                    echo "  └─────────────────────────────────────────┘"
                    [[ -n "$current_deps" ]] && echo "  Depends on: $current_deps"
                    [[ -n "$current_accept" ]] && echo "  Acceptance: $current_accept"
                    [[ -n "$current_details" ]] && echo "  Details: $current_details"
                    echo ""
                fi
                # Start new task
                current_task=$(echo "$line" | sed 's/^### Task [0-9]*: //')
                task_num=$((task_num + 1))
                current_deps=""
                current_accept=""
                current_details=""
                in_task=true
            elif $in_task; then
                if echo "$line" | grep -qiE '^\*\*Dependencies?\*\*:|^\*Dependencies?\*:|^Dependencies?:'; then
                    current_deps=$(echo "$line" | sed 's/^\*\*[Dd]ependencies?\*\*: //; s/^\*[Dd]ependencies?\*: //; s/^[Dd]ependencies?: //')
                elif echo "$line" | grep -qiE '^\*\*Acceptance\*\*:|^\*Acceptance\*:|^Acceptance:'; then
                    current_accept=$(echo "$line" | sed 's/^\*\*Acceptance\*\*: //; s/^\*Acceptance\*: //; s/^Acceptance: //')
                elif echo "$line" | grep -qiE '^\*\*Details?\*\*:|^\*Details?\*:|^Details?:'; then
                    current_details=$(echo "$line" | sed 's/^\*\*Details?\*\*: //; s/^\*Details?\*: //; s/^Details?: //')
                elif echo "$line" | grep -qE '^## '; then
                    in_task=false
                fi
            fi
        done < "$PLAN_FILE"

        # Output last task
        if $in_task && [[ -n "$current_task" ]]; then
            echo "  ┌─────────────────────────────────────────┐"
            echo "  │ TASK $task_num: $current_task"
            echo "  └─────────────────────────────────────────┘"
            [[ -n "$current_deps" ]] && echo "  Depends on: $current_deps"
            [[ -n "$current_accept" ]] && echo "  Acceptance: $current_accept"
            [[ -n "$current_details" ]] && echo "  Details: $current_details"
            echo ""
        fi

        echo "---"
        echo ""
        echo "Risks relevant to implementation:"
        extract_risks | sed 's/^/  /'
        ;;

    tracking)
        # Plan-tracking integration format
        title=$(extract_title | sed 's/^# //')
        task_count=$(count_tasks)
        echo "============================================"
        echo "  PLAN TRACKING IMPORT: $title"
        echo "============================================"
        echo ""
        echo "Plan file: $PLAN_FILE"
        echo "Plan name: $plan_basename"
        echo "Tasks: $task_count total"
        echo ""
        echo "Suggested plan-tracking commands:"
        echo ""
        # Check if plan-tracking scripts exist
        if command -v plan-list.sh &>/dev/null; then
            echo "  # To see all plans:"
            echo "  plan-list.sh"
            echo ""
        fi
        echo "  # To create this plan in the tracking system:"
        echo "  cp \"$PLAN_FILE\" ~/agent-notes/planner/plans/"
        echo ""
        echo "  # After implementation, mark as done:"
        echo "  plan-mark.sh \"$plan_basename\" --status done \\"
        echo "    --commits \"<hash> - <description>\" \\"
        echo "    --by \"<Agent Name>\" \\"
        echo "    --results \"<summary of achievements>\""
        echo ""
        echo "Plan preview:"
        echo "  Title: $title"
        echo "  File: $plan_basename.md"
        echo "  Tasks:"
        grep -n '^### Task [0-9]*:' "$PLAN_FILE" 2>/dev/null | while IFS=: read -r line_num task_line; do
            echo "    • $(echo "$task_line" | sed 's/^[0-9]*:### //')"
        done
        ;;

    *)
        echo "ERROR: Unknown format: $FORMAT"
        echo "Valid formats: default, summary, handoff, tracking"
        exit 1
        ;;
esac
