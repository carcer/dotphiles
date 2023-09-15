#!/usr/bin/env zsh

XEPHYR=`which Xephyr`

Xephyr -ac -br -noreset -name f1 -title f1 -screen 1028x768 :1 &
wait 1
DISPLAY=:1 firefox