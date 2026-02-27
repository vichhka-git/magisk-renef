#!/system/bin/sh
# service.sh - Late-start service for MagiskRenef
MODDIR="${0%/*}"

. "$MODDIR/utils.sh"

# Wait until Android has fully booted
wait_for_boot

# renef_server runs directly from bind-mounted /system/bin/renef_server
# which has u:object_r:system_file:s0 SELinux context (correct for injection).
# Do NOT copy to /data/local/tmp — cp loses the system_file context and
# gains shell_data_file which blocks SELinux injection on Enforcing devices.
RENEF_AGENT="/data/local/tmp/.r"

# Setup libagent.so as /data/local/tmp/.r (file, not directory)
# If a stale .r directory exists from old installs, remove it first
[ -d "$RENEF_AGENT" ] && rm -rf "$RENEF_AGENT"
cp -f /system/lib64/libagent.so "$RENEF_AGENT" 2>/dev/null || \
    cp -f "$MODDIR/system/lib64/libagent.so" "$RENEF_AGENT" 2>/dev/null
chmod +x "$RENEF_AGENT"
# SELinux: app_data_file context required for dlopen into target processes
chcon u:object_r:app_data_file:s0 "$RENEF_AGENT" 2>/dev/null || true

# Start renef_server directly from /system/bin (system_file SELinux context)
setsid /system/bin/renef_server > /data/local/tmp/renef_server.log 2>&1 &

# Verify it came up
check_renef_is_up 5

# Verify it came up
check_renef_is_up 5
