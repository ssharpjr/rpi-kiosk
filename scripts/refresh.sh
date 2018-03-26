#!/usr/bin/env bash

export DISPLAY=":0"
WID=$(xdotool search --onlyvisible --class chromium|head -1)

while true; do
    sleep 300  # Refresh Chromium every 5 minutes
    xdotool windowactivate ${WID}
    xdotool key F5
done