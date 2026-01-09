#!/bin/bash
# Auto-suspend script that works with i3wm
# Suspends system after extended idle period (after screen lock)

# Idle time before suspend (in milliseconds)
# 20 minutes = 1200000 ms
# Screen locks at 10 min, suspend at 20 min total
IDLE_SUSPEND_TIME=1200000

# Check interval (60 seconds)
CHECK_INTERVAL=60

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | systemd-cat -t idle-suspend -p info
}

log_message "Idle suspend monitor started (threshold: $((IDLE_SUSPEND_TIME / 60000)) minutes)"

while true; do
    # Get idle time from X server
    IDLE_TIME=$(xprintidle 2>/dev/null)

    if [ $? -ne 0 ]; then
        log_message "Warning: xprintidle not available, sleeping..."
        sleep $CHECK_INTERVAL
        continue
    fi

    # Check if system is on AC power or battery
    POWER_STATUS=$(cat /sys/class/power_supply/AC*/online 2>/dev/null | head -1)

    # Only auto-suspend on battery (optional - remove this check to always suspend)
    if [ "$POWER_STATUS" != "0" ]; then
        sleep $CHECK_INTERVAL
        continue
    fi

    # Check if idle time exceeds threshold
    if [ "$IDLE_TIME" -gt "$IDLE_SUSPEND_TIME" ]; then
        log_message "Idle threshold exceeded ($IDLE_TIME ms), suspending system..."
        systemctl suspend
    fi

    sleep $CHECK_INTERVAL
done
