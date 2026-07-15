#!/usr/bin/env bash
set -u

LOG="${1:-}"
if [ -z "$LOG" ]; then
  echo "usage: $0 <access-log>" >&2
  exit 1
fi
if [ ! -f "$LOG" ]; then
  echo "見つからない: $LOG" >&2
  exit 1
fi

echo "=== アクセスログ集計: $LOG ==="

echo "--- 総リクエスト数 ---"
wc -l < "$LOG"

echo "--- ステータス内訳 ---"
awk '{print $9}' "$LOG" | sort | uniq -c | sort -rn

echo "--- アクセス上位パス TOP5 ---"
awk '{print $7}' "$LOG" | sort | uniq -c | sort -rn | head -5

echo "--- アクセス元IP TOP5 ---"
awk '{print $1}' "$LOG" | sort | uniq -c | sort -rn | head -5

echo "--- サーバーエラー(5xx)件数 ---"
awk '$9>=500' "$LOG" | wc -l
