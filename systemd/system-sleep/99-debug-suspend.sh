#!/bin/bash
# systemd sleep hook for debugging suspend/resume issues
# This logs all suspend and resume events

LOG_FILE="/var/log/suspend-debug.log"

# Create log file if it doesn't exist (requires sudo first time)
if [ ! -f "$LOG_FILE" ]; then
    sudo touch "$LOG_FILE"
    sudo chmod 666 "$LOG_FILE"
fi

case "$1" in
    pre)
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Preparing to $2" >> "$LOG_FILE"
        echo "  Current suspend mode: $(cat /sys/power/mem_sleep)" >> "$LOG_FILE"
        echo "  Active processes: $(ps aux | wc -l)" >> "$LOG_FILE"
        ;;
    post)
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Waking from $2" >> "$LOG_FILE"
        echo "  Wake successful: YES" >> "$LOG_FILE"
        echo "  Uptime: $(uptime)" >> "$LOG_FILE"
        echo "---" >> "$LOG_FILE"
        ;;
esac
