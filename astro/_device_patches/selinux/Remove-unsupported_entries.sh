# Dynamic One UI SELinux patcher
# Author: @mehedihjoy0

SYSTEM_EXT_PATH="$(GET_PARTITION_PATH "system_ext")"
CIL_NAME="$(head -n 1 "$WORKSPACE/vendor/etc/selinux/plat_sepolicy_vers.txt")"
PATCHED=false

MAPPING_FILE="$SYSTEM_EXT_PATH/etc/selinux/mapping/$CIL_NAME.cil"
VENDOR_PUB_CIL="$WORKSPACE/vendor/etc/selinux/plat_pub_versioned.cil"

if [ ! -f "$MAPPING_FILE" ] || [ ! -f "$VENDOR_PUB_CIL" ]; then
    LOG_WARN "Missing critical SELinux policy files. Skipping dynamic patch."
    return 1
fi

# Create temporary working files
TMP_MAP=$(mktemp)
TMP_VEND=$(mktemp)
TMP_DROP=$(mktemp)

# ==========================================================================
# 1. DYNAMIC SYSTEM/VENDOR TYPE MISMATCH PATCH
# ==========================================================================

# Extract all base types handled by system_ext mapping
sed -n 's/.*(typeattributeset [^ ]* (\([^)]*\))).*/\1/p' "$MAPPING_FILE" | sort -u > "$TMP_MAP"

# Extract all public types supported by target vendor
sed -n 's/.*(type \([^)]*\)).*/\1/p' "$VENDOR_PUB_CIL" | sort -u > "$TMP_VEND"

# Find types present in system mapping but completely missing from vendor
comm -23 "$TMP_MAP" "$TMP_VEND" > "$TMP_DROP"

# Fetch VENDOR_API_LIST for secondary cleanups
VENDOR_API_LIST="$(find "$SYSTEM_EXT_PATH/etc/selinux/mapping" -type f -printf "%f\n" | \
                    sed '/.compat./d' | sed 's/.cil//' | sed 's/\./_/' | sort)"

# Drop the unsupported entries dynamically
while read -r e; do
    [ -z "$e" ] && continue
    PATCHED=true
    LOG "- Dynamic Wipe: \"$e\" SELinux entry not supported by vendor. Removing"
    
    sed -i "/($e)/d" "$MAPPING_FILE"
    for a in $VENDOR_API_LIST; do
        sed -i "/${e}_${a}/d" "$MAPPING_FILE"
    done
    if grep -q "genfscon.*$e" "$SYSTEM_EXT_PATH/etc/selinux/system_ext_sepolicy.cil" 2>/dev/null; then
        sed -i "/genfscon.*$e/d" "$SYSTEM_EXT_PATH/etc/selinux/system_ext_sepolicy.cil"
    fi
    if grep -q "genfscon.*$e" "$WORKSPACE/system/system/etc/selinux/plat_sepolicy.cil" 2>/dev/null; then
        sed -i "/genfscon.*$e/d" "$WORKSPACE/system/system/etc/selinux/plat_sepolicy.cil"
    fi
done < "$TMP_DROP"

# ==========================================================================
# 2. DYNAMIC PROPERTY CONTEXTS DUPLICATE PATCH
# ==========================================================================
if [ -f "$SYSTEM_EXT_PATH/etc/selinux/system_ext_property_contexts" ] && \
   [ -f "$WORKSPACE/vendor/etc/selinux/vendor_property_contexts" ]; then
    
    TMP_SYS_PROP=$(mktemp)
    TMP_VEN_PROP=$(mktemp)
    TMP_PROP_DUP=$(mktemp)

    # Extract clean property tokens (skipping comments/empty lines)
    awk '/^[a-zA-Z0-9_.-]+/ {print $1}' "$SYSTEM_EXT_PATH/etc/selinux/system_ext_property_contexts" | sort -u > "$TMP_SYS_PROP"
    awk '/^[a-zA-Z0-9_.-]+/ {print $1}' "$WORKSPACE/vendor/etc/selinux/vendor_property_contexts" | sort -u > "$TMP_VEN_PROP"

    # Intersect to find properties defined in BOTH layers
    comm -12 "$TMP_SYS_PROP" "$TMP_VEN_PROP" > "$TMP_PROP_DUP"

    while read -r prop; do
        [ -z "$prop" ] && continue
        PATCHED=true
        LOG "- Dynamic Duplicate Wipe: \"$prop\" property found in both layers. Commenting vendor entry."
        sed -i "s|^$prop|#SEC_DUPLICATE: $prop|g" "$WORKSPACE/vendor/etc/selinux/vendor_property_contexts"
    done < "$TMP_PROP_DUP"

    rm -f "$TMP_SYS_PROP" "$TMP_VEN_PROP" "$TMP_PROP_DUP"
fi

# Clean up remaining temp files
rm -f "$TMP_MAP" "$TMP_VEND" "$TMP_DROP"

if ! $PATCHED; then
    LOG "\033[0;33m! Dynamic Analysis complete: Nothing to do\033[0m"
fi
