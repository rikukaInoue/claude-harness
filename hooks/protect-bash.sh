#!/bin/bash
# protect-bash.sh — 危険なBashコマンドをブロックする PreToolUse hook
# exit 2 = bypassPermissions モードでも強制ブロック

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

BLOCKED_PATTERNS=(
  "rm -rf /"
  "rm -rf ~"
  "rm -rf \."
  "DROP TABLE"
  "DROP DATABASE"
  "TRUNCATE TABLE"
  "terraform destroy"
  "git push --force"
  "git push -f "
  "git reset --hard"
  "git clean -fd"
  "sudo rm"
  "sudo shutdown"
  "sudo reboot"
  "mkfs\."
  "> /dev/sd"
  "dd if="
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qi "$pattern"; then
    echo '{"permissionDecision":"deny"}'
    echo "BLOCKED: dangerous command matching '$pattern'" >&2
    exit 2
  fi
done

exit 0
