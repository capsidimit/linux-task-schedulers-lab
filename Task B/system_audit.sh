#!/bin/bash

LOG_DIR="/var/log"
LOG_FILE="${LOG_DIR}/weekly_audit_$(date '+%Y-%m-%d_%H-%M').log"

mkdir -p "$LOG_DIR"

{
    echo "===== SYSTEM AUDIT $(date) ====="
    echo ""

    echo "== Installed packages =="
    if command -v rpm >/dev/null 2>&1; then
        # RPM-based система
        rpm -qa
    elif command -v dpkg >/dev/null 2>&1; then
        # Debian/Ubuntu
        dpkg -l --no-pager
    else
        echo "WARNING: neither rpm nor dpkg found."
    fi

    echo ""
    echo "== File integrity check =="
    if command -v rpm >/dev/null 2>&1; then
        echo "--- rpm -Va ---"
        rpm -Va
    elif command -v debsums >/dev/null 2>&1; then
        echo "--- debsums ---"
        debsums
    else
        echo "WARNING: no integrity tool (rpm -Va or debsums) found."
    fi

    echo ""
    echo "===== END OF AUDIT ====="
} >> "$LOG_FILE" 2>&1