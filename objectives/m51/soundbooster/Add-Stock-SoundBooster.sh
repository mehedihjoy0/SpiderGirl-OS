LOG_BEGIN "- Adding SoundBooster libs from stock"
REMOVE "system" "lib/lib_SAG_EQ_ver*.so"
REMOVE "system" "lib64/lib_SAG_EQ_ver*.so"

REMOVE "system" "lib/lib_SoundBooster_ver*.so"
ADD_FROM_FW "stock" "system" "lib/lib_SoundBooster_ver1000.so"
REMOVE "system" "lib64/lib_SoundBooster_ver*.so"
ADD_FROM_FW "stock" "system" "lib64/lib_SoundBooster_ver1000.so"

REMOVE "system" "lib/lib_SoundAlive_play_plus_ver*.so"
ADD_FROM_FW "stock" "system" "lib/lib_SoundAlive_play_plus_ver400.so"
REMOVE "system" "lib64/lib_SoundAlive_play_plus_ver*.so"
ADD_FROM_FW "stock" "system" "lib64/lib_SoundAlive_play_plus_ver400.so"

ADD_FROM_FW "stock" "system" "lib/libaudiosaplus_sec_legacy.so"
ADD_FROM_FW "stock" "system" "lib64/libaudiosaplus_sec_legacy.so"
ADD_FROM_FW "stock" "system" "lib/libsamsungSoundbooster_plus_legacy.so"
ADD_FROM_FW "stock" "system" "lib64/libsamsungSoundbooster_plus_legacy.so"
LOG_END