#!/usr/bin/env bash
set -u

LOG="${1:-/var/log/auth.log}"   # 引数でログ指定可、既定はauth.log
THRESHOLD="${2:-5}"             # 攻撃とみなす失敗回数の閾値

if [ ! -f "$LOG" ]; then
  echo "log not found: $LOG" >&2
  exit 1
fi

echo "=== auth.log security report: $LOG ==="
echo

echo "[1] 失敗総数"
grep -c "Failed password" "$LOG"     # -c=件数
echo

echo "[2] 攻撃元IP ランキング (上位10)"
grep "Failed password" "$LOG" | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn | head
echo

echo "[3] 狙われたユーザー名 ランキング"
grep "Failed password" "$LOG" | awk '{for(i=1;i<=NF;i++)if($i=="for")print $(i+1)}' | sort | uniq -c | sort -rn | head
echo

echo "[4] 閾値 $THRESHOLD 回超のIP (要警戒)"
grep "Failed password" "$LOG" | awk '{print $(NF-3)}' | sort | uniq -c | \
  awk -v t="$THRESHOLD" '$1 > t {print $2" ("$1"回)"}'
echo

echo "[5] 認証成功 (侵入確認)"
if grep -q "Accepted" "$LOG"; then
  grep "Accepted" "$LOG" | awk '{print $(NF-5), $(NF-3)}'   # 成功したuser/IP概略
else
  echo "成功ログなし"
fi
