LOG_BEGIN "- Adding AIDL vibrator HAL from r9q"
REMOVE "vendor" "bin/hw/vendor.samsung.hardware.vibrator@2.2-service"
REMOVE "vendor" "etc/init/vendor.samsung.hardware.vibrator@2.2-service.rc"
REMOVE "vendor" "lib64/vendor.samsung.hardware.vibrator@2.0.so"
REMOVE "vendor" "lib64/vendor.samsung.hardware.vibrator@2.1.so"
REMOVE "vendor" "lib64/vendor.samsung.hardware.vibrator@2.2.so"
ADD_FROM_FW "r9q" "vendor" "bin/hw/vendor.samsung.hardware.vibrator-service"
ADD_FROM_FW "r9q" "vendor" "etc/init/vendor.samsung.hardware.vibrator-default.rc"
ADD_FROM_FW "r9q" "vendor" "etc/vintf/manifest/vendor.samsung.hardware.vibrator-default.xml"
ADD_FROM_FW "r9q" "vendor" "lib64/vendor.samsung.hardware.vibrator-V3-ndk_platform.so"
LOG_END

LOG_BEGIN "- Patching /vendor/etc/vintf/manifest.xml"
eval "sed -i '/<hal format=\"hidl\">.*/{:a;N;/<\/hal>/!ba;/android.hardware.vibrator/d}' \"$WORKSPACE/vendor/etc/vintf/manifest.xml\""
LOG_END