#!/usr/bin/env bash

set -Eeuo pipefail

# Enterprise Linux Server - User Management Script

if [[ "$EUID" -ne 0 ]]; then
    echo "ERROR: Run this script using sudo."
    exit 1
fi

log() {
    echo "[$(date '+%F %T')] $*"
}

validate_username() {
    [[ "$1" =~ ^[a-z_][a-z0-9_-]*[$]?$ ]]
}

user_exists() {
    getent passwd "$1" >/dev/null 2>&1
}

create_user() {
    read -rp "Enter username to create: " username

    if ! validate_username "$username"; then
        echo "Invalid username."
        return
    fi

    if user_exists "$username"; then
        echo "User already exists."
        return
    fi

    useradd -m -s /bin/bash "$username" ||
        { echo "User creation failed."; return; }

    if passwd "$username"; then
        log "User $username created successfully."
    else
        log "WARNING: User $username was created, but password setup failed."
    fi
}

list_users() {
    echo "Regular user accounts:"
    awk -F: '$3 >= 1000 && $3 < 65534 {
        printf "Username: %-20s UID: %s\n", $1, $3
    }' /etc/passwd
}

lock_user() {
    read -rp "Enter username to lock: " username

    if ! user_exists "$username"; then
        echo "User does not exist."
        return
    fi

    passwd -l "$username"
    log "Account $username locked."
}

unlock_user() {
    read -rp "Enter username to unlock: " username

    if ! user_exists "$username"; then
        echo "User does not exist."
        return
    fi

    passwd -u "$username"
    log "Account $username unlocked."
}

delete_user() {
    read -rp "Enter username to delete: " username

    if ! validate_username "$username"; then
        echo "Invalid username."
        return
    fi

    if [[ "$username" == "root" || "$username" == "$(id -un "${SUDO_USER:-root}")" ]]; then
        echo "Refusing to delete root or the invoking administrator."
        return
    fi

    if ! user_exists "$username"; then
        echo "User does not exist."
        return
    fi

    echo "WARNING: This will delete the user and their home directory."
    read -rp "Type the username '$username' to confirm: " confirmation

    if [[ "$confirmation" != "$username" ]]; then
        echo "Deletion cancelled."
        return
    fi

    userdel -r "$username"
    log "User $username and their home directory deleted."
}

while true; do
    echo
    echo "=================================="
    echo " LINUX USER MANAGEMENT"
    echo "=================================="
    echo "1. Create user"
    echo "2. List users"
    echo "3. Lock user"
    echo "4. Unlock user"
    echo "5. Delete user"
    echo "6. Exit"
    echo

    read -rp "Select an option: " choice

    case "$choice" in
        1) create_user ;;
        2) list_users ;;
        3) lock_user ;;
        4) unlock_user ;;
        5) delete_user ;;
        6) echo "Exiting."; exit 0 ;;
        *) echo "Invalid option. Try again." ;;
    esac
done