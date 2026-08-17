LOG_BEGIN "- Adding missing bluetooth audio HAL from r9q"
BLOBS_LIST="
bin/hw/android.hardware.audio.service
etc/bluetooth_audio_policy_configuration.xml
lib/libsehbluetooth_audio_session.so
lib64/libsehbluetooth_audio_session.so
lib/vendor.samsung.hardware.bluetooth.audio@2.0.so
lib64/vendor.samsung.hardware.bluetooth.audio@2.0.so
lib/vendor.samsung.hardware.bluetooth.audio@2.1.so
lib64/vendor.samsung.hardware.bluetooth.audio@2.1.so
lib/hw/audio.bluetooth.default.so
lib64/hw/audio.bluetooth.default.so
lib/hw/vendor.samsung.hardware.bluetooth.audio@2.1-impl.so
lib64/hw/vendor.samsung.hardware.bluetooth.audio@2.1-impl.so
"
for blob in $BLOBS_LIST; do
    ADD_FROM_FW "r9q" "vendor" "$blob"
done

eval "sed -i '/<!-- hidden sound Audio HAL -->/s|^|\
        <!-- Bluetooth Audio HAL -->\n\
        <xi:include href=\"bluetooth_audio_policy_configuration.xml\"/>\n\n|' \
        \"$WORKSPACE/vendor/etc/audio_policy_configuration_base.xml\""

eval "sed -i '/<name>vendor\.samsung\.hardware\.bluetooth<\/name>/ {
    :a
    N
    /<\/hal>/!ba
    s|.*|&\n\
    <hal format=\"hidl\">\n\
        <name>vendor.samsung.hardware.bluetooth.audio<\/name>\n\
        <transport>hwbinder<\/transport>\n\
        <version>2.1<\/version>\n\
        <interface>\n\
            <name>ISehBluetoothAudioProvidersFactory<\/name>\n\
            <instance>default<\/instance>\n\
        <\/interface>\n\
        <fqname>@2.1::ISehBluetoothAudioProvidersFactory\/default<\/fqname>\n\
    <\/hal>|
}' \"$WORKSPACE/vendor/etc/vintf/manifest.xml\""
LOG_END

# LOG_BEGIN "- Adding audioflinger blobs from m44"
# ADD_FROM_FW "m44" "system" "bin/audioserver"
# ADD_FROM_FW "m44" "system" "lib64/libaudioflinger.so"
# LOG_END

LOG_BEGIN "- Increasing audio offload buffer size $(GET_PROP "vendor" "vendor.audio.offload.buffer.size.kb" "stock") => 256"
BPROP "vendor" "vendor.audio.offload.buffer.size.kb" "256"
LOG_END

LOG_BEGIN "- Increasing speaker volume values 85 => 90"
eval "sed -i -E '/WSA_RX[01] Digital Volume/s/value=\"[^\"]*\"/value=\"90\"/' \
    \"$WORKSPACE/vendor/etc/mixer_paths\"*\".xml\""
LOG_END