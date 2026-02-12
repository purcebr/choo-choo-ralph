#!/usr/bin/env bash
set -e

# ralph-dashboard.sh — Wrapper around ralph.sh that adds dashboard reporting
#
# Usage: ./ralph-dashboard.sh [max_iterations] [--verbose|-v]
#
# Environment variables:
#   DASHBOARD_URL    — Dashboard base URL (default: http://localhost:3001)
#   DASHBOARD_PROJECT_ID — Project ID in dashboard (required)
#   RALPH_FORMAT_SH  — Path to ralph-format.sh (default: ./ralph-format.sh)
#
# This is a drop-in replacement for ralph.sh that tees Claude's stream-json
# output to both the formatter (terminal display) and the dashboard reporter.

DASHBOARD_URL="${DASHBOARD_URL:-http://localhost:3001}"
DASHBOARD_PROJECT_ID="${DASHBOARD_PROJECT_ID:?Set DASHBOARD_PROJECT_ID to the project ID in the dashboard}"
RALPH_FORMAT_SH="${RALPH_FORMAT_SH:-$(dirname "$0")/ralph-format.sh}"
RALPH_REPORT_SH="$(dirname "$0")/ralph-report.sh"

MAX_ITERATIONS=100
VERBOSE_FLAG=""

for arg in "$@"; do
  case "$arg" in
  --verbose | -v)
    VERBOSE_FLAG="--verbose"
    ;;
  [0-9]*)
    MAX_ITERATIONS="$arg"
    ;;
  esac
done

# Generate a unique run ID
RUN_ID="run-$(date +%Y%m%d-%H%M%S)-$$"

echo "Starting Ralph loop (max $MAX_ITERATIONS iterations)"
echo "Dashboard: $DASHBOARD_URL | Project: $DASHBOARD_PROJECT_ID | Run: $RUN_ID"

iteration=0

while [ $iteration -lt $MAX_ITERATIONS ]; do
  echo ""
  echo "=== Iteration $((iteration + 1)) ==="
  echo "---"

  available=$(bd ready --assignee=ralph -n 100 --json 2>/dev/null | jq -r 'length')

  if [ "$available" -eq 0 ]; then
    echo "No ready work available. Done."
    exit 0
  fi

  echo "$available ready task(s) available"
  echo ""

  # Export iteration number for ralph-report.sh
  export RALPH_ITERATION=$((iteration + 1))

  # Tee stream-json to both formatter and dashboard reporter
  claude --dangerously-skip-permissions --output-format stream-json --verbose -p "
Run \`bd ready --assignee=ralph -n 100 --sort=priority\` to see available tasks.

Also run \`bd list --status=in_progress --assignee=ralph\` to see what tasks other Ralph agents are currently working on.

Decide which task to work on next. Selection criteria:
1. Priority - higher priority tasks are more important
2. Avoid conflicts - if other Ralph agents have tasks in_progress, you MUST pick a completely different epic. Do NOT work on any task that is a child, parent, or sibling of an in-progress task. Stay away from the entire epic tree that another Ralph is working on.
3. If all high-priority epics are being worked on by other Ralphs, pick a lower-priority epic that is completely unrelated

Pick ONE task, claim it with \`bd update <id> --status in_progress\`, then execute it according to its description.

One iteration = complete the task AND all its child tasks (if any).

IMPORTANT: After the task and all children are done (or if blocked), EXIT immediately. Do NOT pick up another top-level task. The outer loop will handle the next iteration.
" 2>&1 | tee >("$RALPH_REPORT_SH" "$DASHBOARD_URL" "$RUN_ID" "$DASHBOARD_PROJECT_ID") \
       | "$RALPH_FORMAT_SH" $VERBOSE_FLAG || true

  ((iteration++)) || true
done

echo ""
echo "Reached max iterations ($MAX_ITERATIONS)"
