
#!/bin/bash

LOG=/home/ubuntu/monitor.log
DISK_LIMIT=80
MEM_LIMIT=80

log_msg() {
    echo "$(date '+%F %T') $1" >> "$LOG"
}

check_disk() {
    local usage
    usage=$(df / | tail -1 | awk '{print $5}' | tr -d '%')

    if [ "$usage" -ge "$DISK_LIMIT" ]; then
        log_msg "[WARN] ディスク使用率 ${usage}% (閾値 ${DISK_LIMIT}%)"
    else
        log_msg "[OK] ディスク使用率 ${usage}%"
    fi
}

check_memory() {
    local usage
    usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2*100}')

    if [ "$usage" -ge "$MEM_LIMIT" ]; then
        log_msg "[WARN] メモリ使用率 ${usage}% (閾値 ${MEM_LIMIT}%)"
    else
        log_msg "[OK] メモリ使用率 ${usage}%"
    fi
}

check_disk
check_memoryLOG=/home/ubuntu/monitor.log

