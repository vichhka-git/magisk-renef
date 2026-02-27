#!/system/bin/sh
# service.sh - Late-start service for MagiskRenef
MODDIR="${0%/*}"

. "$MODDIR/utils.sh"

# Wait until Android has fully booted
wait_for_boot

# Mirror the exact manual setup from renef.io/docs/installation.html:
#   1. renef_server -> /data/local/tmp/renef_server (chmod +x)
#   2. libagent.so  -> /data/local/tmp/.r  (FILE named .r, not a dir)
#      chmod +x + SELinux app_data_file context on .r

RENEF_BIN="/data/local/tmp/renef_server"
RENEF_AGENT="/data/local/tmp/.r"

# Copy renef_server from bind-mounted /system/bin (fallback to MODDIR)
cp -f /system/bin/renef_server "$RENEF_BIN" 2>/dev/null || \
    cp -f "$MODDIR/system/bin/renef_server" "$RENEF_BIN" 2>/dev/null
chmod +x "$RENEF_BIN"

# Copy libagent.so as /data/local/tmp/.r (a file, not a directory)
cp -f /system/lib64/libagent.so "$RENEF_AGENT" 2>/dev/null || \
    cp -f "$MODDIR/system/lib64/libagent.so" "$RENEF_AGENT" 2>/dev/null
chmod +x "$RENEF_AGENT"
# SELinux: required so renef_server can dlopen .r into target processes
chcon u:object_r:app_data_file:s0 "$RENEF_AGENT" 2>/dev/null || true

# Start renef_server from /data/local/tmp (same as manual setup)
# setsid detaches from service.sh session; redirect logs
setsid "$RENEF_BIN" > /data/local/tmp/renef_server.log 2>&1 &

# Verify it came up
check_renef_is_up 5
