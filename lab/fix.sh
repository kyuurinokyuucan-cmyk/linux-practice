#!/bin/bash
set -u
LAB="/home/rin/lab"

N=$(base64 -d "$LAB/.answer" 2>/dev/null)
case "$N" in
  1) systemctl start nginx ;;
  2) ufw delete deny 80/tcp ;;
  3) systemctl unmask labtest.service; systemctl start labtest.service ;;
  4) rm -f /mnt/testdisk/filler ;;
  5) pkill -x yes ;;
  *) echo "答えファイルが読めません"; exit 1 ;;
esac

rm -f "$LAB/.answer"
echo "復旧しました (fault $N)"
