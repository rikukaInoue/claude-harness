#!/bin/bash
# file-guard.sh — 機密ファイルへの書き込みをブロックする PreToolUse hook
# Edit / Write ツールに対して適用する

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')

if [ -z "$FILE" ]; then
  exit 0
fi

SENSITIVE_PATTERNS=(
  "\.env$"
  "\.env\."
  "\.pem$"
  "\.key$"
  "\.p12$"
  "\.pfx$"
  "id_rsa"
  "id_ed25519"
  "credentials"
  "secrets/"
  "\.secret"
  "token\.json"
  "service-account"
)

for pattern in "${SENSITIVE_PATTERNS[@]}"; do
  if echo "$FILE" | grep -qiE "$pattern"; then
    echo '{"permissionDecision":"deny"}'
    echo "BLOCKED: write to sensitive file matching '$pattern' ($FILE)" >&2
    exit 2
  fi
done

exit 0
