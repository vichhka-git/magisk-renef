#!/system/bin/sh
# service.sh - Late-start service for MagiskRenef
MODDIR="${0%/*}"

. "$MODDIR/utils.sh"

# Wait until Android has fully booted
wait_for_boot

# Ensure libagent.so is accessible from the expected location
# renef_server looks for libagent.so relative to its working dir
RENEF_SERVER="$MODDIR/system/bin/renef_server"
AGENT_SO="$MODDIR/system/lib64/libagent.so"

# Bind-mount or symlink so renef_server can find libagent.so
# Renef expects libagent.so alongside or in a known path
mkdir -p /data/local/tmp/.r
cp -f "$AGENT_SO" /data/local/tmp/.r/libagent.so 2>/dev/null || true
chmod 755 /data/local/tmp/.r/libagent.so 2>/dev/null || true

# Start renef_server in TCP mode, backgrounded via nohup
# renef_server has no daemon flag — run with nohup + &
if [ -f "$RENEF_SERVER" ]; then
    nohup "$RENEF_SERVER" -t TCP -p 1907 > /data/local/tmp/renef_server.log 2>&1 &
else
    # Fall back to system path (Magisk bind-mount)
    nohup renef_server -t TCP -p 1907 > /data/local/tmp/renef_server.log 2>&1 &
fi

# Verify it came up
check_renef_is_up 5
