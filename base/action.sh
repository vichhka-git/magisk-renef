#!/system/bin/sh
MODPATH=${0%/*}
PATH=$PATH:/data/adb/ap/bin:/data/adb/magisk:/data/adb/ksu/bin

exec 2>> $MODPATH/logs/action.log
set -x

. $MODPATH/utils.sh

[ -f $MODPATH/disable ] && {
    echo "[-] renef_server is disabled (module disabled)"
    exit 0
}

result="$(busybox pgrep 'renef_server')"
if [ -n "$result" ]; then
    echo "[-] Stopping renef_server (PID: $result)..."
    busybox kill -9 $result
    sleep 1
    string="description=Run renef_server on boot: ⏹️ (stopped manually)"
    sed -i "s/^description=.*/$string/g" $MODPATH/module.prop
else
    echo "[-] Starting renef_server..."
    renef_server >> $MODPATH/logs/renef_server.log 2>&1 &
    sleep 1
    check_renef_is_up 3
fi

sleep 1
