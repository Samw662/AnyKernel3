#!/system/bin/sh
AK3_MOD_PATH="/data/adb/modules/ak3-helper/system/vendor/lib/modules"

if [ ! -d "$AK3_MOD_PATH" ]; then
    exit 0
fi

RESETPROP=""
for p in /product/bin/resetprop /data/adb/ksu/bin/resetprop /data/adb/magisk/resetprop; do
    [ -x "$p" ] && RESETPROP="$p" && break
done
[ -z "$RESETPROP" ] && RESETPROP=$(which resetprop 2>/dev/null)
[ -n "$RESETPROP" ] && "$RESETPROP" -n ro.vendor.hw.nfc samsung 2>/dev/null

load_one() {
    base="$1"
    ko="$AK3_MOD_PATH/$base.ko"
    grep -q "^$base " /proc/modules && return 0
    [ -f "$ko" ] || return 1
    insmod "$ko" 2>/dev/null
}

for pass in 1 2 3 4 5 6 7 8 9 10; do
    for ko in "$AK3_MOD_PATH"/*.ko; do
        [ -f "$ko" ] || continue
        base=$(basename "$ko" .ko)
        load_one "$base"
    done
done
