#!/bin/bash
check_disk() {
echo "---disku-usage---"
df -h / | tail -1
}
check_memory() {
echo "---memoryusage---"
free -h | grep Mem
}
check_disk
check_memory

