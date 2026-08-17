LOG "- Patching /vendor/etc/vintf/manifest.xml"
eval "sed -i \
    \"s/type=\\\"device\\\" target-level=\\\"4\\\">/type=\\\"device\\\" target-level=\\\"5\\\">/\" \
    \"$WORKSPACE/vendor/etc/vintf/manifest.xml\""
eval "sed -i \
    '/<hal format=\"hidl\">.*/{:a;N;/<\/hal>/!ba;/android.hardware.configstore/d}' \
    \"$WORKSPACE/vendor/etc/vintf/manifest.xml\""
eval "sed -i \
    \"/^<\/manifest>\\\$/i\\\\    <kernel target-level=\\\"5\\\"\/>\" \
    \"$WORKSPACE/vendor/etc/vintf/manifest.xml\""

REMOVE "vendor" "bin/hw/android.hardware.configstore@1.1-service"
REMOVE "vendor" "etc/init/android.hardware.configstore@1.1-service.rc"
REMOVE "vendor" "etc/seccomp_policy/configstore@1.1.policy"