ADD_FROM_FW "stock" "system" "etc/vintf/compatibility_matrix.device.xml"

eval "sed -i -E '/<compatibility-matrix/s/version=\"[^\"]*\"/version=\"9.0\"/' \
    \"$WORKSPACE/system/system/etc/vintf/compatibility_matrix.device.xml\""
    
eval "sed -i -z 's|<sepolicy-version>[0-9]*\.0</sepolicy-version>\(.*\n[[:space:]]*<sepolicy-version>[0-9]*\.0</sepolicy-version>\)*|\
<sepolicy-version>29.0</sepolicy-version>\n\
        <sepolicy-version>30.0</sepolicy-version>\n\
        <sepolicy-version>31.0</sepolicy-version>\n\
        <sepolicy-version>32.0</sepolicy-version>\n\
        <sepolicy-version>33.0</sepolicy-version>\n\
        <sepolicy-version>34.0</sepolicy-version>\n\
        <sepolicy-version>202404</sepolicy-version>\n\
        <sepolicy-version>202504</sepolicy-version>|g' \
    \"$WORKSPACE/system/system/etc/vintf/compatibility_matrix.device.xml\""