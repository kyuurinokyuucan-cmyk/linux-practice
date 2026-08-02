#!/bin/bash
set -u
LAB="/home/rin/lab"

N=$(base64 -d "$LAB/.answer" 2>/dev/null)
case "$N" in
  1) systemctl start nginx ;;
  2) ufw delete deny 80/tcp > /dev/null; ufw allow 80/tcp > /dev/null ;;
  3) systemctl unmask labtest.service; systemctl start labtest.service ;;
  4) rm -f /mnt/testdisk/filler ;;
  5) pkill -x yes ;;
  6) cp "$LAB/nginx.conf.bak" /etc/nginx/nginx.conf
     nginx -t && systemctl restart nginx ;;
  7) rm -rf /etc/systemd/system/labtest.service.d
     systemctl daemon-reload
     systemctl reset-failed labtest.service
     systemctl restart labtest.service ;;
  8) rm -rf /mnt/testdisk/inodes ;;
  9) pkill -f "tail -f /mnt/testdisk/held" ;;
 10) pkill -f 'a+=($(seq' ;;
  *) echo "答えファイルが読めません"; exit 1 ;;
esac

rm -f "$LAB/.answer"
echo "復旧しました (fault $N)"
