#!/bin/bash
set -u
LAB="/home/rin/lab"
mkdir -p "$LAB"

if ! mountpoint -q /mnt/testdisk; then
  echo "ERROR: /mnt/testdisk がマウントされていません。中止します。"
  exit 1
fi

if [ -f "$LAB/.answer" ]; then
  echo "ERROR: 前回の障害が未復旧です。先に fix.sh を実行してください。"
  exit 1
fi

if [ -f "$LAB/.answer" ]; then
  echo "ERROR: 前回の障害が未復旧です。先に fix.sh を実行してください。"
  exit 1
fi

N=$(( (RANDOM % 10) + 1 ))

case "$N" in
  1) systemctl stop nginx ;;
  2) ufw delete allow 80/tcp > /dev/null; ufw insert 1 deny 80/tcp > /dev/null ;;
  3) systemctl stop labtest.service; systemctl mask labtest.service > /dev/null ;;
  4) fallocate -l 95M /mnt/testdisk/filler ;;
  5) nohup yes > /dev/null 2>&1 &
     nohup yes > /dev/null 2>&1 & ;;
  6) cp /etc/nginx/nginx.conf "$LAB/nginx.conf.bak"
     sed -i '1i bogus_directive on;' /etc/nginx/nginx.conf
     systemctl restart nginx > /dev/null 2>&1 || true ;;
  7) mkdir -p /etc/systemd/system/labtest.service.d
     printf '[Service]\nExecStart=\nExecStart=/usr/bin/nonexistent-binary\n' \
       > /etc/systemd/system/labtest.service.d/break.conf
     systemctl daemon-reload
     systemctl restart labtest.service > /dev/null 2>&1 || true ;;
  8) mkdir -p /mnt/testdisk/inodes
     for i in $(seq 1 30000); do : > "/mnt/testdisk/inodes/f$i" 2>/dev/null || break; done ;;
  9) fallocate -l 90M /mnt/testdisk/held
     nohup tail -f /mnt/testdisk/held > /dev/null 2>&1 &
     sleep 1
     rm -f /mnt/testdisk/held ;;
 10) nohup bash -c 'a=(); while :; do a+=($(seq 1 200000)); sleep 0.5; done' \
       > /dev/null 2>&1 & ;;
esac

echo "$N" | base64 > "$LAB/.answer"
chmod 600 "$LAB/.answer"
echo "仕込み完了。症状から切り分けて。"
