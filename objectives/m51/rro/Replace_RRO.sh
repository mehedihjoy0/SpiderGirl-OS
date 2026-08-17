LOG_BEGIN "- Replacing RRO"
REMOVE "product" "overlay/product_overlay.apk"
cp -r "$SCRPATH/framework-res__m51nsxx__auto_generated_rro_product.apk" "$WORKSPACE/product/overlay"
LOG_END