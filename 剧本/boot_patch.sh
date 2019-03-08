case $((STATUS & 3)) in
  0 )  # Stock boot
    ui_print "- Stock boot image detected"
    ui_print "- Backing up stock boot image"
    SHA1=`./magiskboot --sha1 "$BOOTIMAGE" 2>/dev/null`
    STOCKDUMP=stock_boot_${SHA1}.img.gz
    ./magiskboot --compress "$BOOTIMAGE" $STOCKDUMP
    cp -af ramdisk.cpio ramdisk.cpio.orig 2>/dev/null
    ;;
  1 )  # Magisk patched
    ui_print "- Magisk patched boot image detected"
    # Find SHA1 of stock boot image
    [ -z $SHA1 ] && SHA1=`./magiskboot --cpio ramdisk.cpio sha1 2>/dev/null`
    ./magiskboot --cpio ramdisk.cpio restore
    if ./magiskboot --cpio ramdisk.cpio "exists init.rc"; then
      # Normal boot image
      cp -af ramdisk.cpio ramdisk.cpio.orig
    else
      # A only system-as-root
      rm -f ramdisk.cpio
    fi
    ;;
  2 )  # Unsupported
    ui_print "! Boot image patched by unsupported programs"
    abort "! Please restore back to stock boot image"
    ;;
  3 ) # No ramdisk
    ui_print "- Only kernel stock boot image detected"
    ui_print "- Backing up stock boot image"
    SHA1=`./magiskboot --sha1 "$BOOTIMAGE" 2>/dev/null`
    STOCKDUMP=stock_boot_${SHA1}.img.gz
    ./magiskboot --compress "$BOOTIMAGE" $STOCKDUMP
    STUB=true
    ;;
  4 ) # Magisk stub ramdisk
    ui_print "- Magisk stub boot image detected"
    # Find SHA1 of stock boot image
    [ -z $SHA1 ] && SHA1=`./magiskboot --cpio ramdisk.cpio sha1 2>/dev/null`
    STUB=true
    ;;
esac



##########################################################################################
# Ramdisk patches
##########################################################################################

ui_print "- Patching ramdisk"

echo "KEEPVERITY=$KEEPVERITY" > config
echo "KEEPFORCEENCRYPT=$KEEPFORCEENCRYPT" >> config
[ ! -z $SHA1 ] && echo "SHA1=$SHA1" >> config
if [ -z $STUB ]; then
./magiskboot --cpio ramdisk.cpio \
"add 750 init magiskinit" \
"patch $KEEPVERITY $KEEPFORCEENCRYPT" \
"backup ramdisk.cpio.orig" \
"mkdir 000 .backup" \
"add 000 .backup/.magisk config"
else
   ./magiskboot --cpio ramdisk.cpio \
  "add 750 init magiskinit" \
  "add 000 .backup/.magisk config"
fi
