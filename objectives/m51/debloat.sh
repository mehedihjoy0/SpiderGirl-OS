# Overlays
SYSTEM_DEBLOAT+="
app/WifiRROverlayAppLls
"

# mAFPC
SYSTEM_DEBLOAT+="
bin/mafpc_write
"

# HDCP
SYSTEM_DEBLOAT+="
bin/dhkprov
bin/qchdcpkprov
etc/init/dhkprov.rc
lib64/vendor.samsung.hardware.security.hdcp.keyprovisioning@1.0.so
"

# Apps debloat
SYSTEM_DEBLOAT+="
etc/permissions/privapp-permissions-com.samsung.android.app.earphonetypec.xml
priv-app/EarphoneTypeC
priv-app/IntelligentDynamicFpsService
priv-app/SamsungPositioning
priv-app/OMCAgent5
"

# GameDriver
SYSTEM_DEBLOAT+="
priv-app/GameDriver-SM8450
"

# Esim
SYSTEM_DEBLOAT+="
etc/default-permissions/default-permissions-com.google.android.euicc.xml
etc/permissions/privapp-permissions-com.samsung.android.app.esimkeystring.xml
etc/permissions/privapp-permissions-com.samsung.android.app.telephonyui.esimclient.xml
etc/permissions/privapp-permissions-com.samsung.euicc.mep.xml
etc/permissions/privapp-permissions-com.samsung.euicc.xml
etc/permissions/privapp-permissions-google-euicc.xml
etc/sysconfig/preinstalled-packages-com.samsung.android.app.esimkeystring.xml
priv-app/EsimClient
priv-app/EsimKeyString
"

# qualcomm location
SYSTEM_EXT_DEBLOAT+="
etc/permissions/com.qti.location.sdk.xml
etc/permissions/com.qualcomm.location.xml
etc/permissions/privapp-permissions-com.qualcomm.location.xml
framework/com.qti.location.sdk.jar
priv-app/com.qualcomm.location
"

# system debloat
for debloat in $SYSTEM_DEBLOAT; do
    REMOVE "system" "$debloat"
done

# system_ext
for debloat in $SYSTEM_EXT_DEBLOAT; do
    REMOVE "system_ext" "$debloat"
done