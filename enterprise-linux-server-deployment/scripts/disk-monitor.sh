#!/usr/bin/env bash

set -Eeuo pipefail

# Enterprise Linux Server - Disk Monitoring Script

THRESHOLD="${THRESHOLD:-80}"
HOSTNAME="$(hostname)"

if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]] ||
   ((THRESHOLD < 1 || THRESHOLD > 100)); then
    echo "ERROR: THRESHOLD must be between 1 and 100."
    exit 1
fi

log() {
    echo "[$(date '+%F %T')] $*"
}

send_log() {
    if command -v logger >/dev/null 2>&1; then
        logger -t disk-monitor -- "$1" || true
    fi
}

log "Starting disk usage check on $HOSTNAME"
log "Warning threshold: ${THRESHOLD}%"

WARNING_FOUND=0

while read -r filesystem size used available usage mountpoint; do

    [[ -n "${filesystem:-}" ]] || continue

    percentage="${usage%\%}"

    if ((percentage >= THRESHOLD)); then
        MESSAGE="WARNING: $mountpoint is ${percentage}% full on $HOSTNAME"

        log "$MESSAGE"
        send_log "$MESSAGE"

        WARNING_FOUND=1
    else
        log "OK: $mountpoint is ${percentage}% full"
    fi

done < <(
    df -P -x tmpfs -x devtmpfs -x squashfs -x overlay |
    tail -n +2
)

if ((WARNING_FOUND == 1)); then
    log "Disk monitoring completed with warnings."
    exit 1
fi

log "Disk monitoring completed successfully."