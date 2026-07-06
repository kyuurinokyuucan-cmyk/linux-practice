#!/bin/bash
DATE=$(date "+%Y-%m-%d %H:%M:%S")
LOG=~/health_$(date +%Y%m%d).log

echo "==== Health $DATE ====" >> "$LOG"

echo "[Uptime]" >> "$LOG"
uptime >> "$LOG"

echo "[Disk]" >> "$LOG"
df -h / >> "$LOG"

echo "[Memory]" >> "$LOG"
free -h >> "$LOG"

echo "[CPU Top 5]" >> "$LOG"
ps aux --sort=-%cpu | head -6 >> "$LOG"

echo "完了。ログ: $LOG"

