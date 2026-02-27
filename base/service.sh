#!/system/bin/sh
# service.sh - Late-start service for MagiskRenef
MODDIR="${0%/*}"

. "$MODDIR/utils.sh"

# Wait until Android has fully booted
wait_for_boot

RENEF_AGENT="/data/local/tmp/libagent.so"

# Setup libagent.so at /data/local/tmp/libagent.so
# Remove stale .r directory if it exists from old installs
[ -d /data/local/tmp/.r ] && rm -rf /data/local/tmp/.r
cp -f /system/lib64/libagent.so "$RENEF_AGENT" 2>/dev/null || \
    cp -f "$MODDIR/system/lib64/libagent.so" "$RENEF_AGENT" 2>/dev/null
chmod +x "$RENEF_AGENT"
# SELinux: app_data_file context required for dlopen into target processes
chcon u:object_r:app_data_file:s0 "$RENEF_AGENT" 2>/dev/null || true

# Start renef_server as root from /system/bin (system_file SELinux context)
# renef_server needs root (uid 0) to read /proc/PID/maps of app processes
setsid /system/bin/renef_server > /data/local/tmp/renef_server.log 2>&1 &
echo $! > /data/local/tmp/renef_server.pid

# Verify it came up
check_renef_is_up 5
