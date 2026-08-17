LOG_BEGIN "- Adding vendor sepolicy from r9q"
ADD_FROM_FW "r9q" "vendor" "etc/selinux"

eval "sed -i -E 's/SM-[A-Z0-9]+/$(GET_PROP "vendor" "ro.product.vendor.model" "stock")/g' \
    \"$WORKSPACE/vendor/etc/selinux/vendor_sepolicy_version\""
LOG_END

