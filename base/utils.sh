#!/system/bin/sh
# utils.sh - Shared utilities for MagiskRenef scripts

# Wait for Android to finish booting
wait_for_boot() {
    until [ "$(getprop sys.boot_completed)" = "1" ]; do
        sleep 3
    done
    # Extra settle time for system services
    sleep 2
}

# Check if renef_server is running and update module.prop description
check_renef_is_up() {
    local timeout="${1:-5}"
    local count=0
    local max=$((timeout * 2))

    while [ "$count" -lt "$max" ]; do
        if pgrep renef_server > /dev/null 2>&1 || busybox pgrep renef_server > /dev/null 2>&1 || kill -0 "$(cat /data/local/tmp/renef_server.pid 2>/dev/null)" 2>/dev/null; then
            update_description "✅ renef_server is running (UDS)"
            return 0
        fi
        sleep 1
        count=$((count + 1))
    done

    update_description "❌ renef_server failed to start"
    return 1
}

# Update the description field in module.prop
update_description() {
    local msg="$1"
    local prop="$MODDIR/module.prop"
    if [ -f "$prop" ]; then
        sed -i "s/^description=.*/description=$msg/" "$prop"
    fi
}
