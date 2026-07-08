#!/bin/bash

LOG=/home/ubuntu/disk_check.log
USAGE=$(df / | tail -1 | awk '{print $5}' | tr -d '%')

echo "$(date '+%Y-%m-%d %H:%M:%S') ディスク使用率: ${USAGE}%" >> "$LOG"
