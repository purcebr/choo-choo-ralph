#!/usr/bin/env bash
# ralph-report.sh — Parse Claude stream-json and POST events to Ralph Dashboard
# Usage: ralph-report.sh <dashboard_url> <run_id> <project_id>
#
# Pipe Claude's stream-json output into this script:
#   claude --output-format stream-json ... | tee >(./ralph-report.sh http://localhost:3001 run-123 1) | ./ralph-format.sh

DASHBOARD_URL="${1:?Usage: ralph-report.sh <dashboard_url> <run_id> <project_id>}"
RUN_ID="${2:?Usage: ralph-report.sh <dashboard_url> <run_id> <project_id>}"
PROJECT_ID="${3:?Usage: ralph-report.sh <dashboard_url> <run_id> <project_id>}"
ITERATION="${RALPH_ITERATION:-0}"

post_event() {
  local type="$1"
  local tool="$2"
  local detail="$3"
  local input_tokens="$4"
  local output_tokens="$5"

  curl -s -X POST "${DASHBOARD_URL}/api/events" \
    -H 'Content-Type: application/json' \
    -d "$(jq -cn \
      --arg runId "$RUN_ID" \
      --argjson projectId "$PROJECT_ID" \
      --argjson iteration "$ITERATION" \
      --arg type "$type" \
      --arg tool "$tool" \
      --arg detail "$detail" \
      --argjson inputTokens "${input_tokens:-0}" \
      --argjson outputTokens "${output_tokens:-0}" \
      '{runId: $runId, projectId: $projectId, iteration: $iteration, type: $type, tool: $tool, detail: $detail, tokens: {input: $inputTokens, output: $outputTokens}}'
    )" >/dev/null 2>&1 &
}

# Signal run start
post_event "run_start" "" "Ralph run started" 0 0

while IFS= read -r line; do
  [[ -z "$line" ]] && continue

  type=$(echo "$line" | jq -r '.type // empty' 2>/dev/null)
  [[ -z "$type" ]] && continue

  case "$type" in
    assistant)
      input_tokens=$(echo "$line" | jq -r '.message.usage.input_tokens // 0' 2>/dev/null)
      output_tokens=$(echo "$line" | jq -r '.message.usage.output_tokens // 0' 2>/dev/null)
      cache_read=$(echo "$line" | jq -r '.message.usage.cache_read_input_tokens // 0' 2>/dev/null)
      cache_create=$(echo "$line" | jq -r '.message.usage.cache_creation_input_tokens // 0' 2>/dev/null)
      actual_input=$((input_tokens + cache_read + cache_create))

      # Process content items
      echo "$line" | jq -c '.message.content[]?' 2>/dev/null | while IFS= read -r item; do
        [[ -z "$item" ]] && continue
        item_type=$(echo "$item" | jq -r '.type' 2>/dev/null)

        case "$item_type" in
          text)
            text=$(echo "$item" | jq -r '.text' 2>/dev/null)
            # Check for task-related patterns
            if echo "$text" | grep -qi 'claim\|picking\|working on'; then
              task_id=$(echo "$text" | grep -oE '[a-z]+-mol-[a-z0-9]+' | head -1)
              [[ -n "$task_id" ]] && post_event "task_claimed" "" "Claimed $task_id" 0 0
            fi
            # Truncate for event detail
            detail="${text:0:200}"
            post_event "text_output" "" "$detail" "$actual_input" "$output_tokens"
            ;;
          tool_use)
            name=$(echo "$item" | jq -r '.name' 2>/dev/null)
            case "$name" in
              Bash)
                detail=$(echo "$item" | jq -r '.input.command // empty' 2>/dev/null)
                detail="${detail:0:200}"
                ;;
              Read|Write|Edit)
                detail=$(echo "$item" | jq -r '.input.file_path // empty' 2>/dev/null)
                ;;
              Grep|Glob)
                detail=$(echo "$item" | jq -r '.input.pattern // empty' 2>/dev/null)
                ;;
              Task)
                detail=$(echo "$item" | jq -r '.input.description // empty' 2>/dev/null)
                ;;
              *)
                detail=$(echo "$item" | jq -r '.input.description // empty' 2>/dev/null)
                [[ -z "$detail" ]] && detail="$name"
                ;;
            esac
            post_event "tool_call" "$name" "$detail" "$actual_input" "$output_tokens"
            ;;
        esac
      done
      ;;

    user)
      # Check for tool errors
      echo "$line" | jq -c '.message.content[]?' 2>/dev/null | while IFS= read -r item; do
        [[ -z "$item" ]] && continue
        is_error=$(echo "$item" | jq -r '.is_error // false' 2>/dev/null)
        if [[ "$is_error" == "true" ]]; then
          result=$(echo "$item" | jq -r '.content // empty' 2>/dev/null)
          detail="${result:0:200}"
          post_event "error" "" "$detail" 0 0
        fi

        # Check for task completion patterns in tool results
        result=$(echo "$item" | jq -r '.content // empty' 2>/dev/null)
        if echo "$result" | grep -qi 'status.*closed\|completed\|done'; then
          task_id=$(echo "$result" | grep -oE '[a-z]+-mol-[a-z0-9]+' | head -1)
          [[ -n "$task_id" ]] && post_event "task_completed" "" "Completed $task_id" 0 0
        fi
      done
      ;;

    result)
      post_event "run_end" "" "Ralph iteration completed" 0 0
      ;;
  esac
done

# Wait for any background curl jobs
wait 2>/dev/null
