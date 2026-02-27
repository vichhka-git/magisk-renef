#!/system/bin/sh
# shellcheck disable=SC2034
# SKIPUNZIP=1 not set: let the framework extract all files to $MODPATH
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
        arm64) ;;
        *)
            ui_print "! Unsupported architecture: $ARCH"
            ui_print "! renef_server only supports ARM64"
            abort "Installation aborted."
            ;;
    esac

    ui_print "- Architecture : ARM64"
    ui_print "- Root solution: $(get_root_solution)"
    ui_print ""

    # Files are already extracted to $MODPATH by the framework.
    # Just verify they landed correctly.
    if [ ! -f "$MODPATH/module.prop" ]; then
        abort "! module.prop missing from $MODPATH"
    fi

    if [ ! -f "$MODPATH/system/bin/renef_server" ]; then
        abort "! renef_server missing from $MODPATH/system/bin/"
    fi

    if [ ! -f "$MODPATH/system/lib64/libagent.so" ]; then
        abort "! libagent.so missing from $MODPATH/system/lib64/"
    fi

    ui_print "- Files verified"

    # Update description with installed version
    local ver
    ver=$(grep '^version=' "$MODPATH/module.prop" | cut -d= -f2)
    sed -i "s/^description=.*/description=Renef ${ver} installed. Waiting for boot.../" \
        "$MODPATH/module.prop" 2>/dev/null || true
}

get_root_solution() {
    if [ "$KSU" = "true" ] || [ "$KSU_NEXT" = "true" ]; then
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
