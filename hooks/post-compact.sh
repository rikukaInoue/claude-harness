#!/bin/bash
# post-compact.sh — コンパクション後にコンテキストを再注入する PostToolUse hook
# stdout がそのまま system message として Claude に渡される

# プロジェクトレベルの context-essentials.txt があればそれを使う
if [ -f "$CLAUDE_PROJECT_DIR/.claude/context-essentials.txt" ]; then
  echo "=== Post-Compaction Context Reload ==="
  cat "$CLAUDE_PROJECT_DIR/.claude/context-essentials.txt"
  echo ""
  echo "Re-read CLAUDE.md and your current task plan before proceeding."
  exit 0
fi

# なければ汎用メッセージ
echo "=== Post-Compaction Reminder ==="
echo "Context was just compacted. Before continuing:"
echo "1. Re-read CLAUDE.md for project rules"
echo "2. Re-read your current task plan or MEMORY.md"
echo "3. Verify what you were working on before proceeding"
exit 0
