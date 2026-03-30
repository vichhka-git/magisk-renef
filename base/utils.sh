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
    local retries=$1
    local i=0
    while [ $i -lt $retries ]; do
        if busybox pgrep 'renef_server' > /dev/null 2>&1; then
            local pid
            pid="$(busybox pgrep 'renef_server')"
            echo "[+] renef_server is running (PID: $pid)"
            string="description=Run renef_server on boot: ✅ (running, UDS)"
            sed -i "s/^description=.*/$string/g" $MODPATH/module.prop
            return 0
        fi
        sleep 1
        i=$((i + 1))
    done
    echo "[-] renef_server failed to start"
    string="description=Run renef_server on boot: ❌ (failed)"
    sed -i "s/^description=.*/$string/g" $MODPATH/module.prop
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
