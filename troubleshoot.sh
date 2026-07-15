#!/usr/bin/env bash
set -u

SVC="${1:-}"
if [ -z "$SVC" ]; then
  echo "usage: $0 <service-name>" >&2
  exit 1
fi

WINDOW="-3min"   # 直近この幅だけ見る（古い別障害の混入を防ぐ）

echo "=== 障害切り分け: $SVC ==="

STATE=$(systemctl is-active "$SVC")
echo "[状態] $STATE"

if [ "$STATE" != "active" ]; then
  echo "--- 失敗の詳細 ---"
  systemctl show "$SVC" -p Result,ExecMainStatus,NRestarts
fi

LOG=$(journalctl -u "$SVC" --since "$WINDOW" --no-pager -o cat)

echo "--- 直近ログ ---"
echo "$LOG" | tail -10

echo "--- root-cause 候補 ---"
echo "$LOG" | grep -iE 'error|permission|traceback|failed at step|address already in use|repeated too quickly' | tail -5

if echo "$LOG" | grep -qi 'failed at step'; then
  echo "[ヒント] お膳立て失敗の型 → unitのディレクティブ(User/WorkingDirectory/ExecStart等)を疑え"
elif echo "$LOG" | grep -qiE 'error|traceback|permission'; then
  echo "[ヒント] appが起動して落ちた型 → root-cause行を読め(コード/設定値/権限/依存)"
fi

if echo "$LOG" | grep -qi 'repeated too quickly'; then
  echo "[警告] StartLimit発火中。原因を直してから 'sudo systemctl reset-failed $SVC' が必要"
fi
