#!/bin/bash

echo "[$(date --iso-8601=seconds)]" "Server is" "$(uptime -p)," "space avaliable on root" "$(df -h | egrep "/$" | awk '{print $4}')," "$(who | wc -l)" "active users" >> /tmp/system_report.txt