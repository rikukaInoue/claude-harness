#!/bin/bash
# post-edit-feedback.sh — ファイル編集後にプロジェクト固有のテストを自動実行する PostToolUse hook
# stdout が system message として Claude にフィードバックされる
#
# プロジェクトに .claude/test-command.sh があればそれを実行。
# なければスキップ（何も出力しない）。

TEST_SCRIPT="$CLAUDE_PROJECT_DIR/.claude/test-command.sh"

if [ ! -f "$TEST_SCRIPT" ]; then
  exit 0
fi

echo "=== Auto Feedback: running project tests ==="
OUTPUT=$(bash "$TEST_SCRIPT" 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo "PASSED"
  echo "$OUTPUT" | tail -5
else
  echo "FAILED (exit code: $EXIT_CODE)"
  echo "$OUTPUT" | tail -30
  echo ""
  echo "Fix the failing tests before making further changes."
fi

exit 0
