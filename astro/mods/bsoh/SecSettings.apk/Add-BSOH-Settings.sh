# Scamsung only added this bomb in Galaxy A23

BOMB_MODEL="SM-A236B"
OLD_PROP="ro.product.model"
NEW_PROP="ro.product.astro.model"

LOG_BEGIN "Adding BSOH Settings.."

# Add entries in floating feature

FF "BATTERY_SUPPORT_BSOH_SETTINGS" "TRUE"
FF "BATTERY_SUPPORT_SBP_INFO_SETTINGS" "TRUE"

find . -type f -name "*.smali" | while read -r smali; do
    if grep -q "$BOMB_MODEL" "$smali"; then

        # Replace bomb / plant
        sed -i "s/$BOMB_MODEL/$DEVICE_MODEL/g" "$smali"

        sed -i "s/$OLD_PROP/$NEW_PROP/g" "$smali"

    fi
done

# Real model name in settings
find . -type f -name "ModelNameGetter.smali" | while read -r smali; do
    if grep -q "ro.product.model" "$smali"; then
        sed -i "s/$OLD_PROP/$NEW_PROP/g" "$smali"

    fi
done

LOG_END "BSOH patch applied"
