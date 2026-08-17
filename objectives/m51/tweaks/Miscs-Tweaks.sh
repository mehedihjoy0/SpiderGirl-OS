LOG_BEGIN "- Removing performance capping"
REMOVE "vendor" "etc/hyper"
REMOVE "vendor" "etc/perf"
LOG_END

LOG_BEGIN "- Replacing default zram size with 0"
eval "sed -i -E 's/zramsize=[^\"]*,/zramsize=0,/' \
    \"$WORKSPACE/vendor/etc/fstab.ramplus\""
eval "sed -i -E 's/zramsize=[^\"]*/zramsize=0/' \
    \"$WORKSPACE/vendor/etc/fstab.emmc\""
LOG_END