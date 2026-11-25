#!/usr/bin/env bash

set -uo pipefail

# Enterprise Linux Server - System Health Check

section() {
    echo
    echo "=================================================="
    echo " $1"
    echo "=================================================="
}

run_check() {
    "$@" 2>&1 || echo "Unable to complete this check."
}

section "SYSTEM HEALTH REPORT"

echo "Hostname: $(hostname)"
echo "Date: $(date)"
echo "Uptime: $(uptime -p 2>/dev/null || uptime)"

section "OPERATING SYSTEM"

if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    echo "Distribution: $PRETTY_NAME"
fi

echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"

section "CPU INFORMATION"

run_check lscpu

section "MEMORY USAGE"

run_check free -h

section "DISK USAGE"

run_check df -hT

section "BLOCK DEVICES"

run_check lsblk

section "FAILED SYSTEMD SERVICES"

if command -v systemctl >/dev/null 2>&1; then
    systemctl --failed --no-pager || true
else
    echo "systemctl is unavailable."
fi

section "LISTENING NETWORK PORTS"

if command -v ss >/dev/null 2>&1; then
    ss -tuln || true
else
    echo "ss command is unavailable."
fi

section "TOP CPU-CONSUMING PROCESSES"

ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 6

section "RECENT SYSTEM ERRORS"

if command -v journalctl >/dev/null 2>&1; then
    journalctl -p err --since "1 hour ago" -n 20 --no-pager ||
        echo "Unable to retrieve journal entries."
else
    echo "journalctl is unavailable."
fi

section "HEALTH CHECK COMPLETED"

echo "Report generated at: $(date '+%F %T')"