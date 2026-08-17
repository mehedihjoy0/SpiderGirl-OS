LOG_BEGIN "- Adding Polarr libs from a73xq"
ADD_FROM_FW "a73xq" "system" "etc/public.libraries-polarr.txt"
ADD_FROM_FW "a73xq" "system" "lib64/libBestComposition.polarr.so"
ADD_FROM_FW "a73xq" "system" "lib64/libFeature.polarr.so"
ADD_FROM_FW "a73xq" "system" "lib64/libPolarrSnap.polarr.so"
ADD_FROM_FW "a73xq" "system" "lib64/libTracking.polarr.so"
ADD_FROM_FW "a73xq" "system" "lib64/libYuv.polarr.so"
LOG_END

LOG_BEGIN "- Adding camera libs from stock"
ADD_FROM_FW "stock" "system" "lib64/liblow_light_hdr.arcsoft.so"
ADD_FROM_FW "stock" "system" "lib64/libhigh_dynamic_range.arcsoft.so"
ADD_FROM_FW "stock" "system" "lib64/libhumantracking.arcsoft.so"
ADD_FROM_FW "stock" "system" "lib64/libhumantracking_util.camera.samsung.so"
ADD_FROM_FW "stock" "system" "lib64/libveengine.arcsoft.so"
LOG_END

LOG_BEGIN "- Adding AIDL snap HAL from r9q"
BLOBS_LIST="
bin/hw/vendor.samsung.hardware.snap@1.2-service
etc/init/vendor.samsung.hardware.snap@1.2-service.rc
lib/vendor.samsung.hardware.snap@1.0.so
lib/vendor.samsung.hardware.snap@1.1.so
lib/vendor.samsung.hardware.snap@1.2.so
lib64/vendor.samsung.hardware.snap@1.0.so
lib64/vendor.samsung.hardware.snap@1.1.so
lib64/vendor.samsung.hardware.snap@1.2.so
"
for blob in $BLOBS_LIST; do
    REMOVE "vendor" "$blob"
done

BLOBS_LIST="
bin/hw/vendor.samsung.hardware.snap-service
etc/init/vendor.samsung.hardware.snap-default.rc
lib64/libsnap_compute.so
lib64/libsnap_compute_wrapper.so
lib64/libsnap_v1.samsung.so
lib64/libsnap_vndk.so
lib64/libsnaplite_native.so
lib64/libsnaplite_wrapper.so
lib64/vendor.samsung.hardware.snap-V1-ndk_platform.so
"
for blob in $BLOBS_LIST; do
    ADD_FROM_FW "r9q" "vendor" "$blob"
done

ADD_CONTEXT "vendor" "bin/hw/vendor.samsung.hardware.snap-service" "snap_hidl_exec"

eval "sed -i '/<hal format=\"hidl\" optional=\"true\">/{N; /vendor.samsung.hardware.snap/{N;N;N;N;N;N;N; s|.*|\
    <hal format=\"aidl\">\n\
        <name>vendor.samsung.hardware.snap</name>\n\
        <version>3</version>\n\
        <interface>\n\
            <name>ISehSnap</name>\n\
            <instance>default</instance>\n\
        </interface>\n\
    </hal>|}}' \
    \"$WORKSPACE/system/system/etc/vintf/compatibility_matrix.device.xml\""

eval "sed -i '/<hal format=\"hidl\">/{N; /vendor.samsung.hardware.snap/{N;N;N;N;N;N;N;N; s|.*|\
    <hal format=\"aidl\">\n\
        <name>vendor.samsung.hardware.snap</name>\n\
        <fqname>ISehSnap/default</fqname>\n\
    </hal>|}}' \
    \"$WORKSPACE/vendor/etc/vintf/manifest.xml\""
LOG_END

LOG_BEGIN "- Fixing portrait preview"
ADD_FROM_FW "stock" "system" "cameradata/portrait_data/single_bokeh_feature.json"
eval "sed -i '/\"LD_FD_engine\"/,/}/ s/\"mode_preview\": null/\"mode_preview\": \"true\"/' \
    \"$WORKSPACE/system/system/cameradata/portrait_data/single_bokeh_feature.json\""
LOG_END

LOG_BEGIN "- Patching /vendor/ueventd.rc"
eval "cat \"$SCRPATH/ueventd.rc.diff\" >> \"$WORKSPACE/vendor/ueventd.rc\""
LOG_END

LOG_BEGIN "- Replacing midas blobs from source"
REMOVE "vendor" "etc/midas"
ADD_FROM_FW "main" "vendor" "etc/midas"
sed -i "s|a73xq|$DEVICE_CODENAME|g" "$WORKSPACE/vendor/etc/midas/midas_config.json"
LOG_END

LOG_BEGIN "- Adding singletake blobs from source"
REMOVE "vendor" "etc/singletake"
ADD_FROM_FW "main" "vendor" "etc/singletake"
LOG_END