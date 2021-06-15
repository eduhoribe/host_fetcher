#!/usr/bin/env sh

# autor: Eduwardo Horibe
# description: POSIX compliant shell script to update hosts file from an URL (https://github.com/StevenBlack/hosts as default)
# version: 0.1

DEBUG=false

HOSTS_URL="https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
HOSTS_FILE_PATH="/etc/hosts"
HOSTS_FILE_BACKUP_PATH="$HOSTS_FILE_PATH.bkp"
TEMP_FILE_PATH="/tmp/hosts_tmp"

info() {
    echo "info.: $*"
}

debug() {
    if $DEBUG; then
        echo "debug: $*"
    fi
}

error() {
    echo "error: $*"
    exit 1
}

check_read_and_write_permissions() {
    if ! [ -r "$*" ] || ! [ -w "$*" ]; then
        error "User does not have read/write permission to file $*"
    fi
}

continue_yes_or_no_question() {
    printf "info.: %s (y/n) " "$*"

    old_stty_cfg=$(stty -g)
    stty raw -echo
    answer=$(head -c 1)
    stty "$old_stty_cfg"
    echo
    if echo "$answer" | grep -iqv "^y"; then
        info "Aborting..."
        exit 1
    fi
}

load_current_hosts_file() {
    debug "Hashing current hosts file"
    current_hosts_hash=$(sha256sum <"$HOSTS_FILE_PATH")
    debug "OLD_HASH -> $current_hosts_hash"
}

fetch_new_hosts_file() {
    debug "Fetching hosts file in $HOSTS_URL"
    curl -s -o "$TEMP_FILE_PATH" "$HOSTS_URL"

    debug "Hashing new hosts file"
    hosts_hash=$(sha256sum <"$TEMP_FILE_PATH")

    debug "NEW_HASH -> $hosts_hash"
}

check_read_and_write_permissions $HOSTS_FILE_PATH
check_read_and_write_permissions $TEMP_FILE_PATH

if [ -f "$HOSTS_FILE_PATH" ]; then
    debug "Hosts file exists!"

    load_current_hosts_file
    fetch_new_hosts_file

    if [ "$hosts_hash" != "$current_hosts_hash" ]; then
        info "Files are different! Saving the old one in $HOSTS_FILE_BACKUP_PATH"

        if [ -f $HOSTS_FILE_BACKUP_PATH ]; then
            continue_yes_or_no_question "Backup file already exists. Overwrite?"
        fi

        mv "$HOSTS_FILE_PATH" "$HOSTS_FILE_BACKUP_PATH"
    else
        info "Files are the same! Exiting..."
        exit 0
    fi
else
    debug "Hosts file does not exists! Creating..."
fi

cat "$TEMP_FILE_PATH" >"$HOSTS_FILE_PATH"
info "Done!"

exit 0
