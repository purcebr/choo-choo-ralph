#!/usr/bin/env bash
set -e

# Schedule a Ralph run for a specific time using the OS `at` command.
# Ralph picks up whatever pending beads exist when it starts.
#
# Usage:
#   ralph-schedule.sh <time> <project-dir> [max-iterations]
#   ralph-schedule.sh --list
#   ralph-schedule.sh --cancel <at-job-id>
#
# Examples:
#   ralph-schedule.sh "11:00 PM" ~/Documents/git/brypod 50
#   ralph-schedule.sh "tomorrow 6am" ~/Documents/git/brypod
#   ralph-schedule.sh --list
#   ralph-schedule.sh --cancel 42
#
# Requires:
#   - 'at' command enabled (macOS: sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.atrun.plist)

# --- List queued at jobs ---
if [[ "$1" == "--list" ]]; then
  atq
  exit 0
fi

# --- Cancel an at job ---
if [[ "$1" == "--cancel" ]]; then
  id="$2"
  if [[ -z "$id" ]]; then
    echo "Usage: ralph-schedule.sh --cancel <at-job-id>"
    exit 1
  fi
  atrm "$id"
  echo "Cancelled at job $id"
  exit 0
fi

# --- Schedule a new run ---
TIME_SPEC="$1"
PROJECT_DIR="$2"
MAX_ITERATIONS="${3:-100}"

if [[ -z "$TIME_SPEC" || -z "$PROJECT_DIR" ]]; then
  echo "Usage: ralph-schedule.sh <time> <project-dir> [max-iterations]"
  echo ""
  echo "Examples:"
  echo "  ralph-schedule.sh \"11:00 PM\" ~/Documents/git/brypod 50"
  echo "  ralph-schedule.sh \"tomorrow 6am\" ~/Documents/git/brypod"
  echo "  ralph-schedule.sh --list"
  echo "  ralph-schedule.sh --cancel 42"
  exit 1
fi

# Resolve project directory
PROJECT_DIR=$(cd "$PROJECT_DIR" && pwd)

if [[ ! -d "$PROJECT_DIR/.beads" ]]; then
  echo "Error: No .beads/ directory at $PROJECT_DIR"
  exit 1
fi

# Schedule with 'at' — Ralph picks up pending beads automatically
echo "cd \"$PROJECT_DIR\" && ./ralph-dashboard.sh $MAX_ITERATIONS > \"$PROJECT_DIR/.choo-choo-ralph/run-\$(date +%Y%m%d-%H%M%S).log\" 2>&1" \
  | at "$TIME_SPEC" 2>&1

echo ""
echo "Scheduled Ralph run:"
echo "  Project:    $(basename "$PROJECT_DIR")"
echo "  Time:       $TIME_SPEC"
echo "  Iterations: $MAX_ITERATIONS"
echo "  Log:        $PROJECT_DIR/.choo-choo-ralph/run-*.log"
echo ""
echo "View queued:  ralph-schedule.sh --list"
echo "Cancel:       ralph-schedule.sh --cancel <job-id>"
