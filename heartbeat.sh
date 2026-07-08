#!/bin/bash
while true; do
    echo "稼働中: $(date)" >> /home/ubuntu/heartbeat.log
    sleep 10
done
