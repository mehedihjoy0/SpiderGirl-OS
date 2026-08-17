LOG_BEGIN "- Replacing radio HAL version with 1.5"
eval "sed -i \"s/1.4::IRadio/1.5::IRadio/g\" \"$WORKSPACE/vendor/etc/vintf/manifest.xml\""
LOG_END