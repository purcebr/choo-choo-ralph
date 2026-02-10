#!/usr/bin/env bash
set -e

# Choo Choo Ralph - Single interactive iteration
# Usage: ./ralph-once.sh

echo "=== Ralph Single Iteration ==="

# Check if any open molecule roots are available
available=$(bd list --ready --assignee ralph --type epic -n 100 --json 2>/dev/null | jq -r 'length')

if [ "$available" -eq 0 ]; then
  echo "No open work available."
  exit 0
fi

echo "$available open task(s) available"
echo ""

# Run Claude interactively - let it see available work and pick one
claude "
Run \`bd list --ready --assignee ralph --type epic --sort priority -n 100\` to see available molecule roots.

Decide which task to work on next. This should be the one YOU decide has the highest priority - not necessarily the first in the list.

Pick ONE task, claim it with \`bd update <id> --status in_progress\`, then execute it according to its description.

IMPORTANT - Finding ready steps within a molecule:
When the task description tells you to find ready steps, use:
  \`bd --no-daemon ready --mol <your-molecule-id>\`
Do NOT use \`bd ready --parent <id>\` as it will incorrectly show no results due to parent-child blocking semantics.

One iteration = complete the task AND all its child tasks (if any).

After the task and all children are done (or if blocked), EXIT. This is a single iteration.
"
