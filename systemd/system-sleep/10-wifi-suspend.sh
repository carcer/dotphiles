#!/bin/bash
# Workaround for MT7925 WiFi+Bluetooth combo suspend bugs on Framework 13 AMD
#
# WiFi (mt7925e, PCIe): driver fails to suspend with error -110 (timeout),
# causing the system to crash/hang instead of entering suspend. Known bug in
# Linux kernel 6.12+ affecting MT7925 (RZ717) Wi-Fi 7 cards.
#
# Bluetooth (btusb, USB): after resume, the BT USB endpoint sometimes fails
# to re-enumerate, leaving `bluetoothctl` with "No default controller
# available" until reboot. Cycling btusb around suspend forces clean
# re-enumeration on resume.
#
# References:
# - https://community.frame.work/t/framework-13-ryzen-ai-350-wont-suspend-in-linux-due-to-mt7925e/70830
# - https://bugs.launchpad.net/bugs/2095279

WIFI_MODULE="mt7925e"
BT_MODULE="btusb"

case "$1" in
    pre)
        echo "$(date): Unloading $BT_MODULE and $WIFI_MODULE before suspend" | systemd-cat -t wifi-suspend -p info
        modprobe -r $BT_MODULE
        modprobe -r $WIFI_MODULE
        ;;
    post)
        echo "$(date): Reloading $WIFI_MODULE and $BT_MODULE after resume" | systemd-cat -t wifi-suspend -p info
        modprobe $WIFI_MODULE
        modprobe $BT_MODULE
        ;;
esac
