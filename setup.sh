#!/bin/bash
# setup.sh — プロジェクトに claude-harness を展開する
#
# Usage:
#   claude-harness/setup.sh [project-dir]
#
# 引数なしの場合はカレントディレクトリに展開する

set -euo pipefail

HARNESS_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${1:-.}"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"

echo "=== Claude Harness Setup ==="
echo "Harness:  $HARNESS_DIR"
echo "Project:  $PROJECT_DIR"
echo ""

# .claude ディレクトリ作成
mkdir -p "$PROJECT_DIR/.claude"

# --- settings.json ---
SETTINGS_FILE="$PROJECT_DIR/.claude/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
  echo "[skip] .claude/settings.json already exists"
else
  sed "s|__HARNESS_DIR__|$HARNESS_DIR|g" "$HARNESS_DIR/templates/settings.json" > "$SETTINGS_FILE"
  echo "[created] .claude/settings.json"
fi

# --- CLAUDE.md ---
CLAUDE_MD="$PROJECT_DIR/CLAUDE.md"
if [ -f "$CLAUDE_MD" ]; then
  echo "[skip] CLAUDE.md already exists"
else
  sed "s|__PROJECT_NAME__|$PROJECT_NAME|g" "$HARNESS_DIR/templates/CLAUDE.md" > "$CLAUDE_MD"
  echo "[created] CLAUDE.md"
fi

# --- context-essentials.txt ---
CONTEXT_FILE="$PROJECT_DIR/.claude/context-essentials.txt"
if [ -f "$CONTEXT_FILE" ]; then
  echo "[skip] .claude/context-essentials.txt already exists"
else
  cp "$HARNESS_DIR/templates/context-essentials.txt" "$CONTEXT_FILE"
  echo "[created] .claude/context-essentials.txt"
fi

# --- test-command.sh ---
TEST_COMMAND="$PROJECT_DIR/.claude/test-command.sh"
if [ -f "$TEST_COMMAND" ]; then
  echo "[skip] .claude/test-command.sh already exists"
else
  cp "$HARNESS_DIR/templates/test-command.sh" "$TEST_COMMAND"
  chmod +x "$TEST_COMMAND"
  echo "[created] .claude/test-command.sh"
fi

echo ""
echo "Done! Next steps:"
echo "  1. Edit CLAUDE.md with your project-specific rules"
echo "  2. Edit .claude/test-command.sh with your project's test command"
echo "  3. Edit .claude/context-essentials.txt with your current task info"
echo "  4. Review .claude/settings.json and adjust permissions as needed"
