#!/bin/bash
# harness-log.sh — 全 hook から呼ばれる共通ログ関数
# JSONL 形式で記録する
#
# Usage: source harness-log.sh
#        harness_log "hook_name" "event" "detail"

HARNESS_LOG_FILE="${CLAUDE_HARNESS_LOG_FILE:-$HOME/.claude/harness-metrics.jsonl}"

harness_log() {
  local hook="$1"
  local event="$2"
  local detail="$3"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local project
  project="${CLAUDE_PROJECT_DIR:-unknown}"
  local session
  session="${CLAUDE_SESSION_ID:-unknown}"

  printf '{"ts":"%s","hook":"%s","event":"%s","detail":"%s","project":"%s","session":"%s"}\n' \
    "$timestamp" "$hook" "$event" "$detail" "$project" "$session" \
    >> "$HARNESS_LOG_FILE"
}
