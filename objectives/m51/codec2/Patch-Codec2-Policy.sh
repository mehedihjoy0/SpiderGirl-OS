# https://github.com/devcore94/MonsterROM/blob/seventeen/platform/exynos2100/patches/codec2/customize.sh
# https://github.com/devcore94/MonsterROM/blob/seventeen/platform/exynos2100/patches/stock_props/customize.sh

LOG_BEGIN "- Applying codec2-patch"

CODEC2_POLICY="$WORKSPACE/vendor/etc/seccomp_policy/samsung.software.media.c2-base-policy"

if [ -f "$CODEC2_POLICY" ]; then
    LOG "- Updating mremap rule in $CODEC2_POLICY"
    # Replace the existing line if present
    sed -i 's/^mremap: arg3 == 3$/mremap: arg3 == 3 || arg3 == MREMAP_MAYMOVE/' "$CODEC2_POLICY"

    # If the line wasn't found, append it
    if ! grep -q "mremap: arg3 == 3 || arg3 == MREMAP_MAYMOVE" "$CODEC2_POLICY"; then
        echo "mremap: arg3 == 3 || arg3 == MREMAP_MAYMOVE" >> "$CODEC2_POLICY"
    fi
    
    uniq "$WORKSPACE/system/system/build.prop" "$WORKSPACE/system/system/tmp" && mv -f "$WORKSPACE/system/system/tmp" "$WORKSPACE/system/system/build.prop"
    LOG "- Adding \"debug.codec2.stop_hal_before_surface\" prop with \"1\" in /system/system/build.prop"
    sed -i "/spatializer_enabled=true/a debug.codec2.stop_hal_before_surface=1" "$WORKSPACE/system/system/build.prop"
    sed -i "/stop_hal_before_surface/i ro.audio.spatializer_enabled=true" "$WORKSPACE/system/system/build.prop"
    sed -i "/PRODUCT_SYSTEM_DEFAULT_PROPERTIES/a ####################################" "$WORKSPACE/system/system/build.prop"
fi

LOG_END