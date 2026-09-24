#!/bin/bash

# Resize vendor partition for DLKM modules
# Based on AnyKernel3 DLKM support

VENDOR_BLOCK="/dev/block/by-name/vendor"
VENDOR_SIZE_MB=90

if [ ! -e "$VENDOR_BLOCK" ]; then
echo "Vendor block not found, skipping resize"
exit 0
fi

echo "Resizing vendor partition by ${VENDOR_SIZE_MB}MB..."

# Get current size
CURRENT_SIZE=$(/sbin/blockdev --getsize64 "$VENDOR_BLOCK")
NEW_SIZE=$((CURRENT_SIZE + VENDOR_SIZE_MB * 1024 * 1024))

# Resize filesystem first
e2fsck -fy "$VENDOR_BLOCK" || true
resize2fs "$VENDOR_BLOCK" "${NEW_SIZE}" || true

# Resize partition
parted "$VENDOR_BLOCK" resizepart 1 "${NEW_SIZE}B" || true

# Resize filesystem again to fill partition
resize2fs "$VENDOR_BLOCK" || true

echo "Vendor partition resized successfully"
exit 0
