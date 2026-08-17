local TMP_DIR="/tmp/out/kernel_extracted"
eval "mkdir -p \"$TMP_DIR\""

DOWNLOAD_KERNEL()
{    
    KERNEL_REPO="https://api.github.com/repos/kurtnettle/android_kernel_samsung_sm7150/releases/latest"
    KERNEL_URL=$(curl -s ${GITHUB_TOKEN:+-H "Authorization: token $GITHUB_TOKEN"} \
        "$KERNEL_REPO" | grep -o 'https://[^"]*m51-ksu[^"]*\.zip' | head -n1)    
    KERNEL_ZIP="$TMP_DIR/LostPrime-Kernel-m51.zip"
    BOOT_URL="https://github.com/mehedihjoy0/M51-Device-Tree/raw/refs/heads/main/boot/boot.img"

	SILENT wget -O "$DIROUT/boot.img" "$BOOT_URL"
	SILENT wget -O "$KERNEL_ZIP" "$KERNEL_URL"
}

EXTRACT_KERNEL()
{
    eval "unzip -oq \"$KERNEL_ZIP\" -d \"$TMP_DIR\""
    
    BOOT_FILE="boot.img"
    eval "cp -a \"$DIROUT/$BOOT_FILE\" \"$TMP_DIR/$BOOT_FILE\""
    
    MKBOOT_FILEIMG_ARGS="$($PREBUILTS/android-tools/unpack_bootimg --boot_img "$TMP_DIR/$BOOT_FILE" --out "$TMP_DIR/out" --format mkbootimg 2>&1)"

    OUT_KERNEL="$(find "$TMP_DIR/out" -maxdepth 1 -type f \( -name "kernel" -o -name "Image" -o -name "zImage" \) | LC_ALL=C sort | head -n 1)"
    
    OUT_DTB="$(find "$TMP_DIR/out" -maxdepth 1 -type f -name "dtb" | LC_ALL=C sort | head -n 1)"
}

DETECT_KERNEL_FORMAT() {
    local file="$1"

    if head -c2 "$file" | od -An -tx1 | grep -q "1f 8b"; then
        echo "gz"
        return
    fi

    if head -c4 "$file" | od -An -tx1 | grep -q "04 22 4d 18"; then
        echo "lz4"
        return
    fi

    echo "raw"
}

PATCH_KERNEL()
{
    DTBO_FILE="dtbo.img"

    KERNEL_IMG="$(find "$TMP_DIR" -type f \( -name "Image" -o -name "Image.gz" -o -name "Image.lz4" -o -name "zImage" \) | LC_ALL=C sort | head -n 1)"
    DTB_IMG="$TMP_DIR/dtb"
    DTBO_IMG="$TMP_DIR/dtbo.img"

    WORK_FMT=$(DETECT_KERNEL_FORMAT "$OUT_KERNEL")
    NEW_FMT=$(DETECT_KERNEL_FORMAT "$KERNEL_IMG")

    if [[ "$WORK_FMT" != "$NEW_FMT" ]]; then
        case "$WORK_FMT" in
            gz)
                if [[ "$NEW_FMT" == "raw" ]]; then
                    gzip -9 -c "$KERNEL_IMG" > "${KERNEL_IMG}.gz"
                    KERNEL_IMG="${KERNEL_IMG}.gz"
                elif [[ "$NEW_FMT" == "lz4" ]]; then
                    lz4 -d "$KERNEL_IMG" -c | gzip -9 > "${KERNEL_IMG}.gz"
                    KERNEL_IMG="${KERNEL_IMG}.gz"
                fi
            ;;

            lz4)
                if [[ "$NEW_FMT" == "raw" ]]; then
                    lz4 -9 "$KERNEL_IMG" "${KERNEL_IMG}.lz4"
                    KERNEL_IMG="${KERNEL_IMG}.lz4"
                elif [[ "$NEW_FMT" == "gz" ]]; then
                    gzip -d -c "$KERNEL_IMG" | lz4 -9 > "${KERNEL_IMG}.lz4"
                    KERNEL_IMG="${KERNEL_IMG}.lz4"
                fi
            ;;

            raw)
                if [[ "$NEW_FMT" == "gz" ]]; then
                    gzip -d -c "$KERNEL_IMG" > "${KERNEL_IMG%.gz}"
                    KERNEL_IMG="${KERNEL_IMG%.gz}"
                elif [[ "$NEW_FMT" == "lz4" ]]; then
                    lz4 -d "$KERNEL_IMG" -c > "${KERNEL_IMG%.lz4}"
                    KERNEL_IMG="${KERNEL_IMG%.lz4}"
                fi
            ;;
        esac
    fi

    eval "cp -af \"$KERNEL_IMG\" \"$OUT_KERNEL\""
    eval "cp -af \"$DTB_IMG\" \"$OUT_DTB\""

    eval "$PREBUILTS/android-tools/mkbootimg $MKBOOT_FILEIMG_ARGS -o \"$TMP_DIR/new-$BOOT_FILE\""

    eval "mv -f \"$TMP_DIR/new-$BOOT_FILE\" \"$DIROUT/$BOOT_FILE\""    
    eval "mv -f \"$DTBO_IMG\" \"$DIROUT/$DTBO_FILE\""

    eval "rm -rf \"$TMP_DIR\""
}

DOWNLOAD_KERNEL
EXTRACT_KERNEL
PATCH_KERNEL