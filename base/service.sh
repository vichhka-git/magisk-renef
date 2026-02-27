#!/system/bin/sh
# service.sh - Late-start service for MagiskRenef
MODDIR="${0%/*}"

. "$MODDIR/utils.sh"

# Wait until Android has fully booted
wait_for_boot

# After bind-mount, renef_server is accessible at /system/bin/renef_server
# Copy libagent.so to /data/local/tmp/libagent.so (where renef_server expects it)
# chmod 777 + SELinux app_data_file context required for dlopen into target processes
cp -f /system/lib64/libagent.so /data/local/tmp/libagent.so 2>/dev/null || \
    cp -f "$MODDIR/system/lib64/libagent.so" /data/local/tmp/libagent.so 2>/dev/null || true
chmod 777 /data/local/tmp/libagent.so 2>/dev/null || true
chcon u:object_r:app_data_file:s0 /data/local/tmp/libagent.so 2>/dev/null || true

# Start renef_server in UDS mode (default)
# Use setsid to detach from the service.sh process group
# Redirect stdout/stderr to log file
setsid /system/bin/renef_server > /data/local/tmp/renef_server.log 2>&1 &

# Verify it came up
check_renef_is_up 5
