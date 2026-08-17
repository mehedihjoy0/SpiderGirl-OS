LOG_BEGIN "- Adding \"ro.netflix.bsp_rev\" prop with \"Q7250-19133-1\" in /system/system/build.prop"
eval "sed -i \"/ro.smps.gain.spk/i ro.netflix.bsp_rev=Q7250-19133-1\" \"$WORKSPACE/system/system/build.prop\""
LOG_END