#!/usr/bin/env bash

set -Eeuo pipefail

# Enterprise Linux Server - Backup Script

BACKUP_DIR="${BACKUP_DIR:-/var/backups/enterprise-linux-server}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

log() {
    echo "[$(date '+%F %T')] $*"
}

error_exit() {
    log "ERROR: $*"
    exit 1
}

[[ "$EUID" -eq 0 ]] || error_exit "Run this script with sudo or as root."

[[ "$RETENTION_DAYS" =~ ^[0-9]+$ ]] ||
    error_exit "RETENTION_DAYS must be a non-negative integer."

command -v tar >/dev/null || error_exit "tar is not installed."
command -v sha256sum >/dev/null || error_exit "sha256sum is not installed."

if (($# > 0)); then
    SOURCES=("$@")
else
    SOURCES=(/etc /var/www /home)
fi

RELATIVE_SOURCES=()

for source in "${SOURCES[@]}"; do
    [[ "$source" == /* ]] || error_exit "Source must be an absolute path: $source"
    [[ -e "$source" ]] || error_exit "Source does not exist: $source"

    RELATIVE_SOURCES+=("${source#/}")
done

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

ARCHIVE="$BACKUP_DIR/backup-${TIMESTAMP}.tar.gz"
TEMP_FILE="$(mktemp "$BACKUP_DIR/backup-${TIMESTAMP}.XXXXXX")"

cleanup() {
    [[ -n "${TEMP_FILE:-}" ]] && rm -f "$TEMP_FILE"
}

trap cleanup EXIT

log "Starting backup..."
log "Backup destination: $BACKUP_DIR"

tar -czpf "$TEMP_FILE" --numeric-owner \
    -C / "${RELATIVE_SOURCES[@]}" ||
    error_exit "Backup archive creation failed."

mv "$TEMP_FILE" "$ARCHIVE"
TEMP_FILE=""

chmod 600 "$ARCHIVE"

sha256sum "$ARCHIVE" > "${ARCHIVE}.sha256"
chmod 600 "${ARCHIVE}.sha256"

log "Backup completed successfully."
log "Archive: $ARCHIVE"

log "Removing backups older than $RETENTION_DAYS days..."

find "$BACKUP_DIR" -maxdepth 1 -type f \
    -name 'backup-*.tar.gz' \
    -mtime "+$RETENTION_DAYS" -delete

find "$BACKUP_DIR" -maxdepth 1 -type f \
    -name 'backup-*.tar.gz.sha256' \
    -mtime "+$RETENTION_DAYS" -delete

log "Backup process finished."