# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=Lithium kernel
dev.string=zRyu
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=lavender
supported.versions=
supported.patchlevels=
'; } # end properties

# shell variables
block=/dev/block/bootdevice/by-name/boot;
is_slot_device=0;
ramdisk_compression=auto;

## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;

## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
set_perm_recursive 0 0 755 644 $ramdisk/*;
set_perm_recursive 0 0 750 750 $ramdisk/init* $ramdisk/sbin;

ui_print " "
ui_print "press any volume key first"
ui_print "select cam blobs according to your rom"

# Keycheck
INSTALLER=$(pwd)
KEYCHECK=$INSTALLER/tools/keycheck
chmod 755 $KEYCHECK

keytest() {
  (/system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" > $INSTALLER/events) || return 1
  return 0
}

choose() {
  #note from chainfire @xda-developers: getevent behaves weird when piped, and busybox grep likes that even less than toolbox/toybox grep
  while true; do
    /system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" > $INSTALLER/events
    if (`cat $INSTALLER/events 2>/dev/null | /system/bin/grep VOLUME >/dev/null`); then
      break
    fi
  done
  if (`cat $INSTALLER/events 2>/dev/null | /system/bin/grep VOLUMEUP >/dev/null`); then
    return 0
  else
    return 1
  fi
}

chooseold() {
  # Calling it first time detects previous input. Calling it second time will do what we want
  $KEYCHECK
  $KEYCHECK
  SEL=$?
  if [ "$1" == "UP" ]; then
    UP=$SEL
  elif [ "$1" == "DOWN" ]; then
    DOWN=$SEL
  elif [ $SEL -eq $UP ]; then
    return 0
  elif [ $SEL -eq $DOWN ]; then
    return 1
  else
    ui_print "   Vol key not detected!"
    abort "   Use name change method in TWRP"
  fi
}

if [ -z $NEW ]; then
  if keytest; then
    FUNCTION=choose
  else
    FUNCTION=chooseold
    ui_print " "
    ui_print "- Vol Key Programming -"
    ui_print "   Press Volume Up Key: "
    $FUNCTION "UP"
    ui_print "   Press Volume Down Key: "
    $FUNCTION "DOWN"
  fi
  ui_print " "
  ui_print "- Select Option -"
  ui_print "  Choose cam blobs: "
  ui_print "  + Volume Up = NEWCAM for MIUI etc "
  ui_print "  - Volume Down = OLDCAM for any rom base aosp "
  if $FUNCTION; then
    NEW=true
  else
    NEW=false
  fi
else
  ui_print "   Option specified in zipname!"
fi

## AnyKernel install
dump_boot;

  # Kernel choose
  if $NEW; then
    cat /tmp/anykernel/Image.gz-dtb-nc > /tmp/anykernel/Image.gz-dtb;
    ui_print " installing newcam nad boost phone.... "
  else
    cat /tmp/anykernel/Image.gz-dtb-oc > /tmp/anykernel/Image.gz-dtb;
    ui_print " installing oldcam and boost phone..... and press any volume key"
  fi
  
  if [ -z $HOME ]; then
  if keytest; then
    FUNCTION=choose
  else
    FUNCTION=chooseold
    $FUNCTION "UP"
    $FUNCTION "DOWN"
  fi
  ui_print " "
  ui_print "  DO YOU WANT TO DISABLE THERMAL ? "
  ui_print "  + YES "
  ui_print "  - NO "
  if $FUNCTION; then
    HOME=true
  else
    HOME=false
  fi
else
  ui_print "   Option specified in zipname!"
fi

   #module thermal selection
   if $HOME; then
    rm -rf /data/adb/modules/LithiumEx;
    rm -rf /data/adb/modules/VendettaEx;
    cp -rf  $home/magisk_module /data/adb/modules/LithiumEx;
    ui_print " Disable thermal selected and lithiumEx started... "
   else
    rm -rf /data/adb/modules/LithiumEx;
    rm -rf /data/adb/modules/VendettaEx;
    cp -rf $home/module /data/adb/modules/LithiumEx;
    ui_print " Enable thermal selected and lithiumEx started... "
   fi
   
write_boot;
## end install

