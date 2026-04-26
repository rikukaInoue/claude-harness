#!/bin/bash
# harness-stats.sh — harness-metrics.jsonl を集計して表示する
#
# Usage:
#   harness-stats.sh              # 全期間
#   harness-stats.sh today        # 今日
#   harness-stats.sh week         # 直近7日
#   harness-stats.sh 2026-04-26   # 指定日以降

set -euo pipefail

LOG_FILE="${CLAUDE_HARNESS_LOG_FILE:-$HOME/.claude/harness-metrics.jsonl}"

if [ ! -f "$LOG_FILE" ]; then
  echo "No metrics found at $LOG_FILE"
  exit 0
fi

# 期間フィルタ
SINCE=""
case "${1:-all}" in
  today)
    SINCE=$(date -u +"%Y-%m-%d")
    ;;
  week)
    SINCE=$(date -u -v-7d +"%Y-%m-%d" 2>/dev/null || date -u -d "7 days ago" +"%Y-%m-%d")
    ;;
  all)
    SINCE=""
    ;;
  *)
    SINCE="$1"
    ;;
esac

if [ -n "$SINCE" ]; then
  DATA=$(jq -c "select(.ts >= \"$SINCE\")" "$LOG_FILE")
  echo "=== Harness Metrics (since $SINCE) ==="
else
  DATA=$(cat "$LOG_FILE")
  echo "=== Harness Metrics (all time) ==="
fi

if [ -z "$DATA" ]; then
  echo "No events found."
  exit 0
fi

echo ""

# 総イベント数
TOTAL=$(echo "$DATA" | wc -l | tr -d ' ')
echo "Total events: $TOTAL"
echo ""

# hook 別の集計
echo "--- By Hook ---"
echo "$DATA" | jq -r '.hook' | sort | uniq -c | sort -rn | while read count hook; do
  printf "  %-20s %s\n" "$hook" "$count"
done
echo ""

# event 別の集計
echo "--- By Event ---"
echo "$DATA" | jq -r '[.hook, .event] | join(":")' | sort | uniq -c | sort -rn | while read count key; do
  printf "  %-30s %s\n" "$key" "$count"
done
echo ""

# ブロック数
BLOCKS=$(echo "$DATA" | jq -r 'select(.event == "blocked")' | wc -l | tr -d ' ')
echo "--- Safety ---"
echo "  Dangerous commands blocked:  $(echo "$DATA" | jq -r 'select(.hook == "protect-bash" and .event == "blocked")' | wc -l | tr -d ' ')"
echo "  Sensitive files blocked:     $(echo "$DATA" | jq -r 'select(.hook == "file-guard" and .event == "blocked")' | wc -l | tr -d ' ')"
echo ""

# テスト結果
PASSED=$(echo "$DATA" | jq -r 'select(.hook == "test-feedback" and .event == "passed")' | wc -l | tr -d ' ')
FAILED=$(echo "$DATA" | jq -r 'select(.hook == "test-feedback" and .event == "failed")' | wc -l | tr -d ' ')
TOTAL_TESTS=$((PASSED + FAILED))
if [ "$TOTAL_TESTS" -gt 0 ]; then
  RATE=$((PASSED * 100 / TOTAL_TESTS))
  echo "--- Test Feedback ---"
  echo "  Passed: $PASSED  Failed: $FAILED  Rate: ${RATE}%"
  echo ""
fi

# diff サイズ警告
DIFF_WARNINGS=$(echo "$DATA" | jq -r 'select(.hook == "diffsize" and .event == "warning")' | wc -l | tr -d ' ')
if [ "$DIFF_WARNINGS" -gt 0 ]; then
  echo "--- Commit Reminders ---"
  echo "  Diff size warnings: $DIFF_WARNINGS"
  echo ""
fi

# コンパクション
COMPACTIONS=$(echo "$DATA" | jq -r 'select(.hook == "compact")' | wc -l | tr -d ' ')
if [ "$COMPACTIONS" -gt 0 ]; then
  echo "--- Compaction ---"
  echo "  Context compactions: $COMPACTIONS"
  echo ""
fi

# セッション別の稼働時間
echo "--- Sessions ---"
echo "$DATA" | jq -r '[.session, .ts] | join("\t")' | sort -t$'\t' -k1,1 -k2,2 | \
  awk -F'\t' '
  {
    if ($1 != prev && prev != "") {
      cmd = "date -j -f \"%Y-%m-%dT%H:%M:%SZ\" \"" last "\" +%s 2>/dev/null || date -d \"" last "\" +%s 2>/dev/null"
      cmd | getline end_ts; close(cmd)
      cmd = "date -j -f \"%Y-%m-%dT%H:%M:%SZ\" \"" first "\" +%s 2>/dev/null || date -d \"" first "\" +%s 2>/dev/null"
      cmd | getline start_ts; close(cmd)
      dur = end_ts - start_ts
      mins = int(dur / 60)
      printf "  %s: %d min (%d events)\n", prev, mins, count
    }
    if ($1 != prev) {
      prev = $1
      first = $2
      count = 0
    }
    last = $2
    count++
  }
  END {
    if (prev != "") {
      cmd = "date -j -f \"%Y-%m-%dT%H:%M:%SZ\" \"" last "\" +%s 2>/dev/null || date -d \"" last "\" +%s 2>/dev/null"
      cmd | getline end_ts; close(cmd)
      cmd = "date -j -f \"%Y-%m-%dT%H:%M:%SZ\" \"" first "\" +%s 2>/dev/null || date -d \"" first "\" +%s 2>/dev/null"
      cmd | getline start_ts; close(cmd)
      dur = end_ts - start_ts
      mins = int(dur / 60)
      printf "  %s: %d min (%d events)\n", prev, mins, count
    }
  }'
