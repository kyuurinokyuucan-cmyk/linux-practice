#!/bin/bash
set -u
LAB="/home/rin/lab"
mkdir -p "$LAB"

N=$(( (RANDOM % 5) + 1 ))

case "$N" in
  1) systemctl stop nginx ;;
  2) ufw insert 1 deny 80/tcp > /dev/null ;;
  3) systemctl stop labtest.service; systemctl mask labtest.service > /dev/null ;;
  4) fallocate -l 95M /mnt/testdisk/filler ;;
  5) nohup yes > /dev/null 2>&1 &
     nohup yes > /dev/null 2>&1 & ;;
esac

echo "$N" | base64 > "$LAB/.answer"
chmod 600 "$LAB/.answer"
echo "仕込み完了。何が起きているか、症状から切り分けて。"
