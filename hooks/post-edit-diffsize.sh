#!/bin/bash
# post-edit-diffsize.sh — 未コミットの変更が大きくなりすぎたら警告する PostToolUse hook
# Edit/Write 後に発火し、diff の行数で判定する

THRESHOLD="${CLAUDE_HARNESS_DIFF_THRESHOLD:-100}"

if [ ! -d "$CLAUDE_PROJECT_DIR/.git" ]; then
  exit 0
fi

DIFF_LINES=$(cd "$CLAUDE_PROJECT_DIR" && git diff --stat 2>/dev/null | tail -1 | grep -oE '[0-9]+ insertion|[0-9]+ deletion' | grep -oE '[0-9]+' | paste -sd+ - | bc 2>/dev/null || echo 0)

if [ "$DIFF_LINES" -ge "$THRESHOLD" ]; then
  echo "=== Diff Size Warning ==="
  echo "Uncommitted changes: ${DIFF_LINES} lines (threshold: ${THRESHOLD})"
  echo "Consider committing now to create a save point."
fi

exit 0
