if [ -f "$STOCK_FW/system/system/priv-app/HybridRadio/HybridRadio.apk" ]; then
    LOG_BEGIN "- Adding FM radio blobs from a52q"
    ADD_FROM_FW "a52q" "system" "etc/permissions/privapp-permissions-com.sec.android.app.fm.xml"
	ADD_FROM_FW "a52q" "system" "etc/sysconfig/preinstalled-packages-com.sec.android.app.fm.xml"
	ADD_FROM_FW "a52q" "system" "priv-app/HybridRadio/HybridRadio.apk"
	ADD_FROM_FW "a52q" "system" "lib/libfmradio_jni.so"
	ADD_FROM_FW "a52q" "system" "lib64/libfmradio_jni.so"
	ADD_FROM_FW "a52q" "system_ext" "lib/fm_helium.so"
	ADD_FROM_FW "a52q" "system_ext" "lib/libfm-hci.so"
	ADD_FROM_FW "a52q" "system_ext" "lib/vendor.qti.hardware.fm@1.0.so"
	ADD_FROM_FW "a52q" "system_ext" "lib64/fm_helium.so"
	ADD_FROM_FW "a52q" "system_ext" "lib64/libfm-hci.so"
	ADD_FROM_FW "a52q" "system_ext" "lib64/vendor.qti.hardware.fm@1.0.so"
    LOG_END
    
    ADD_PATCH "HybridRadio.apk" \
        "$SCRPATH/HybridRadio.apk/Spoof-Model.sh"
fi