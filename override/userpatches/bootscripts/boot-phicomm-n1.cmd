# DO NOT EDIT THIS FILE
#
# Please edit /boot/armbianEnv.txt to set supported parameters
#

setenv load_addr "0x32000000"
setenv kernel_addr_r "0x34000000"
setenv fdt_addr_r "0x4080000"
setenv overlay_error "false"
# default values
setenv rootdev "/dev/mmcblk1p1"
setenv verbosity "1"
setenv console "both"
setenv bootlogo "false"
setenv rootfstype "ext4"
setenv docker_optimizations "on"
setenv INITRD "uInitrd"
setenv LINUX "Image"
setenv devnum 1
setenv devtype "mmc"
setenv prefix "/boot/"

if test -e usb 0 /u-boot.bin; then
    setenv devnum 0
    setenv devtype "usb"
    setenv prefix "/"
fi

echo "devnum: ${devnum}"
echo "devtype: ${devtype}"
echo "Current prefix: ${prefix}"

if test -e ${devtype} ${devnum} ${prefix}armbianEnv.txt; then
    echo "load ${devtype} ${devnum} ${load_addr} ${prefix}armbianEnv.txt"
    load ${devtype} ${devnum} ${load_addr} ${prefix}armbianEnv.txt
    env import -t ${load_addr} ${filesize}
    echo "Current fdtfile after armbianEnv: ${fdtfile}"
else
    echo "Not found armbianEnv.txt"
fi

echo "Current ethaddr: ${ethaddr}"

if test -e ${devtype} ${devnum} ${prefix}${INITRD}; then
    bootfileexist="true"
else
    bootfileexist="false"
    echo "Not found INITRD"
fi

if test -e ${devtype} ${devnum} ${prefix}${LINUX}; then
    bootfileexist="true"
else
    bootfileexist="false"
    echo "Not found LINUX"
fi

if test -e ${devtype} ${devnum} ${prefix}dtb/${fdtfile}; then
    bootfileexist="true"
else
    bootfileexist="false"
    echo "Not found DTB"
fi

if test "${bootfileexist}" = "true"; then
    if test "${console}" = "display" || test "${console}" = "both"; then setenv consoleargs "console=ttyAML0,115200 console=tty1"; fi
    if test "${console}" = "serial"; then setenv consoleargs "console=ttyAML0,115200"; fi
    if test "${bootlogo}" = "true"; then setenv consoleargs "bootsplash.bootfile=bootsplash.armbian ${consoleargs}"; fi

    setenv bootargs "root=${rootdev} rootwait rootfstype=${rootfstype} ${consoleargs} consoleblank=0 coherent_pool=2M loglevel=${verbosity} libata.force=noncq usb-storage.quirks=${usbstoragequirks} ${extraargs} ${extraboardargs}"
    if test "${docker_optimizations}" = "on"; then setenv bootargs "${bootargs} cgroup_enable=memory swapaccount=1"; fi
    echo "Mainline bootargs: ${bootargs}"

    echo "load ${devtype} ${devnum} ${ramdisk_addr_r} ${prefix}${INITRD}"
    load ${devtype} ${devnum} ${ramdisk_addr_r} ${prefix}${INITRD}

    echo "load ${devtype} ${devnum} ${kernel_addr_r} ${prefix}${LINUX}"
    load ${devtype} ${devnum} ${kernel_addr_r} ${prefix}${LINUX}

    echo "load ${devtype} ${devnum} ${fdt_addr_r} ${prefix}dtb/${fdtfile}"
    load ${devtype} ${devnum} ${fdt_addr_r} ${prefix}dtb/${fdtfile}
    fdt addr ${fdt_addr_r}
    fdt resize 65536

    for overlay_file in ${overlays}; do
        if load ${devtype} ${devnum} ${load_addr} ${prefix}dtb/amlogic/overlay/${overlay_prefix}-${overlay_file}.dtbo; then
            echo "Applying kernel provided DT overlay ${overlay_prefix}-${overlay_file}.dtbo"
            fdt apply ${load_addr} || setenv overlay_error "true"
        fi
    done

    for overlay_file in ${user_overlays}; do
        if load ${devtype} ${devnum} ${load_addr} ${prefix}overlay-user/${overlay_file}.dtbo; then
            echo "Applying user provided DT overlay ${overlay_file}.dtbo"
            fdt apply ${load_addr} || setenv overlay_error "true"
        fi
    done

    if test "${overlay_error}" = "true"; then
        echo "Error applying DT overlays, restoring original DT"
        load ${devtype} ${devnum} ${fdt_addr_r} ${prefix}dtb/${fdtfile}
    else
        if load ${devtype} ${devnum} ${load_addr} ${prefix}dtb/amlogic/overlay/${overlay_prefix}-fixup.scr; then
            echo "Applying kernel provided DT fixup script (${overlay_prefix}-fixup.scr)"
            source ${load_addr}
        fi
        if test -e ${devtype} ${devnum} ${prefix}fixup.scr; then
            load ${devtype} ${devnum} ${load_addr} ${prefix}fixup.scr
            echo "Applying user provided fixup script (fixup.scr)"
            source ${load_addr}
        fi
    fi

    booti ${kernel_addr_r} ${ramdisk_addr_r} ${fdt_addr_r}
fi

# Recompile with:
# mkimage -C none -A arm -T script -d /boot/boot.cmd /boot/boot.scr
