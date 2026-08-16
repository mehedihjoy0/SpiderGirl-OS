find . -type f -name "*.smali" -exec \
	sed -i -E "s|SM-A525F|${DEVICE_MODEL}|g" {} +