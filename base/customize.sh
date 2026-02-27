#!/system/bin/sh
# shellcheck disable=SC2034
SKIPUNZIP=1
SKIPMOUNT=false
PROPFILE=false
POSTFSDATA=false
LATESERVICE=true

print_modname() {
    ui_print "**************************************************"
    ui_print "           MagiskRenef - Renef for Android        "
    ui_print "        Dynamic Instrumentation via Magisk         "
    ui_print "**************************************************"
}

on_install() {
    # renef only supports ARM64
    case "$ARCH" in
        arm64)
            F_ARCH="arm64"
            ;;
        *)
            ui_print "! Unsupported architecture: $ARCH"
            ui_print "! renef_server only supports ARM64"
            abort "Installation aborted."
            ;;
    esac

    ui_print "- Architecture : $F_ARCH"
    ui_print "- Root solution: $(get_root_solution)"
    ui_print ""

    # Create target directories
    mkdir -p "$MODPATH/system/bin"
    mkdir -p "$MODPATH/system/lib64"

    # Extract renef_server
    ui_print "- Extracting renef_server..."
    unzip -o "$ZIPFILE" "system/bin/renef_server" -d "$MODPATH" >&2
    if [ ! -f "$MODPATH/system/bin/renef_server" ]; then
        abort "! renef_server not found in module zip!"
    fi

    # Extract libagent.so
    ui_print "- Extracting libagent.so..."
    unzip -o "$ZIPFILE" "system/lib64/libagent.so" -d "$MODPATH" >&2
    if [ ! -f "$MODPATH/system/lib64/libagent.so" ]; then
        abort "! libagent.so not found in module zip!"
    fi

    ui_print "- Files installed successfully"
}

get_root_solution() {
    if [ "$KSU" = "true" ]; then
        echo "KernelSU"
    elif [ "$APATCH" = "true" ]; then
        echo "APatch"
    else
        echo "Magisk"
    fi
}

set_permissions() {
    set_perm_recursive "$MODPATH" root root 0755 0644
    set_perm "$MODPATH/system/bin/renef_server" root root 0755 u:object_r:system_file:s0
    set_perm "$MODPATH/system/lib64/libagent.so" root root 0644 u:object_r:system_file:s0
}

# Check if module was disabled after install
if [ -f "$MODPATH/disable" ]; then
    ui_print "- Module disabled, skipping service setup"
fi

# Update description with install status
sed -i "s/^description=.*/description=Renef v$(grep '^version=' "$MODPATH/module.prop" | cut -d= -f2) installed. Waiting for boot.../" \
    "$MODPATH/module.prop" 2>/dev/null || true
