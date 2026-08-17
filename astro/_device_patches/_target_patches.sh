# ==============================================================================
#
# MOD_NAME="Target devices patches"
# MOD_AUTHOR="Salvo Giangreco , ExtremeXT , ShaDisNX255"
# MOD_DESC="Apply device related features on source firmware."
#
# ==============================================================================

# NOTE This is not completed yet.

# Set target model name
FF_IF_DIFF "stock" "SETTINGS_CONFIG_BRAND_NAME"

# Set target ssrm policy
FF "SYSTEM_CONFIG_SIOP_POLICY_FILENAME" "$DEVICE_SIOP_POLICY_FILENAME"

# Set target codename
BPROP "system" "ro.astro.codename" "$(GET_PROP "vendor" "ro.product.vendor.name" "stock")"

# Set target model
BPROP "system" "ro.product.astro.model" "$DEVICE_MODEL"

# Display
FF_IF_DIFF "stock" "COMMON_CONFIG_MDNIE_MODE"
FF_IF_DIFF "stock" "LCD_SUPPORT_AMOLED_DISPLAY"