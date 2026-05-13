#!/bin/bash
# Workaround for MT7925E WiFi driver suspend bug
# Unloads WiFi driver before suspend, reloads after resume
#
# This fixes the issue where the mt7925e driver fails to suspend with
# error -110 (timeout), causing the system to crash/hang instead of
# entering suspend. This is a known bug in Linux kernel 6.12+ affecting
# Framework Laptop 13 AMD Ryzen AI systems with MT7925 (RZ717) Wi-Fi 7 card.
#
# References:
# - https://community.frame.work/t/framework-13-ryzen-ai-350-wont-suspend-in-linux-due-to-mt7925e/70830
# - https://bugs.launchpad.net/bugs/2095279

WIFI_MODULE="mt7925e"

case "$1" in
    pre)
        # Before suspend: unload WiFi driver
        echo "$(date): Unloading $WIFI_MODULE before suspend" | systemd-cat -t wifi-suspend -p info
        modprobe -r $WIFI_MODULE
        ;;
    post)
        # After resume: reload WiFi driver
        echo "$(date): Reloading $WIFI_MODULE after resume" | systemd-cat -t wifi-suspend -p info
        modprobe $WIFI_MODULE
        ;;
esac
