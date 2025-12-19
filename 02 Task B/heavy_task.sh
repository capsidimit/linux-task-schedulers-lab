#!/bin/bash

if ! command -v stress-ng &> /dev/null
then
    echo -e "Command stress-ng could not be found. Please install stress-ng dependency!"
    exit 1
fi

echo "[$(date --iso-8601=seconds)]" "$(cat /proc/loadavg)" > /tmp/load_before_task.log
stress-ng --cpu 2 --timeout 30s
echo "[$(date --iso-8601=seconds)]" "$(cat /proc/loadavg)" > /tmp/load_after_task.log