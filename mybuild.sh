#!/bin/sh

# ./OrangePI-Kernel/build/config.good/sun8iw7p1smp_lobo_defconfig.opiplus

TMPF=`mktemp -d /tmp/OPIXXX_$$`
CURD=`pwd`
OUTDIR=build
SRCFOLDER=OrangePiPlus-Kernel
LOBOSRCDIR=${SRCFOLDER}/OrangePI-Kernel
SD_CARD_FILE=./sdcard.img
ROOTPWD="toor" # Must be changed @first login

end()
{
        sudo rm -rf $TMPF
        exit 0
}

trap end 9 2

# $1 = exit code
# $2 the message
myexit () {
	echo $2
	sudo rm -rf $TMPF
	rm -f $SD_CARD_FILE
	exit $1
}

get_sources() {
	if [ -d $SRCFOLDER ]; then
		echo "Source folder ${SRCFOLDER} exists, updating ..."
		(cd $SRCFOLDER ; git pull)
	else
		git clone https://github.com/j75/OrangePiPlus-Kernel.git
	fi
}

build_script() {
	echo "Building script.bin.${1}_${2}_${3}"

	#cp ${LOBOSRCDIR}/build/orange_pi_plus.fex ${OUTDIR}/sys_config.fex
	grep -v "^;" ${LOBOSRCDIR}/build/orange_pi_plus.fex > ${OUTDIR}/sys_config.fex
	# 720p50
	cat ${OUTDIR}/sys_config.fex | sed s/"screen0_output_mode      = 10"/"screen0_output_mode      = 4"/g > ${OUTDIR}/_sys_config.fex
	mv ${OUTDIR}/_sys_config.fex ${OUTDIR}/sys_config.fex
	cat ${OUTDIR}/sys_config.fex | sed s/"screen1_output_mode      = 10"/"screen1_output_mode      = 4"/g > ${OUTDIR}/_sys_config.fex
	# max. frequency: 1.2 GHz
	perl -pi -e "s|^extremity_freq.*|extremity_freq     = 1200000000|g" ${OUTDIR}/_sys_config.fex
	
	mv ${OUTDIR}/_sys_config.fex ${OUTDIR}/sys_config.fex
}

# http://linux-sunxi.org/H3_Manual_build_howto
build_fex_script() {
	if [ ! -f ${OUTDIR}/sys_config.fex ]; then
		myexit 11 "No ${OUTDIR}/sys_config.fex file!"
	fi

	echo "Fex file compiler requires fex file in CRLF format"
	unix2dos ${OUTDIR}/sys_config.fex
	echo "${LOBOSRCDIR}/pctools/linux/mod_update/script"
	${LOBOSRCDIR}/pctools/linux/mod_update/script ${OUTDIR}/sys_config.fex
	echo "Compile fex file"
	fex2bin ${OUTDIR}/sys_config.fex ${OUTDIR}/sys_config.bin
	echo "Patch sdcard boot0"
	cp ${LOBOSRCDIR}/chips/sun8iw7p1/bin/boot0_sdcard_sun8iw7p1.bin ${OUTDIR}/boot0_sdcard.fex
	echo "${LOBOSRCDIR}/pctools/linux/mod_update/update_boot0"
	${LOBOSRCDIR}/pctools/linux/mod_update/update_boot0 ${OUTDIR}/boot0_sdcard.fex ${OUTDIR}/sys_config.bin SDMMC_CARD
}

build_bin () {
	if [ -d ${OUTDIR} ]; then
		echo "Output folder ${OUTDIR} exists, ..."
	else
		mkdir ${OUTDIR}

		build_script "OPI-PLUS" "720p50" "hdmi"
	fi
}


build_uboot_legacy () {
	if [ -f ${LOBOSRCDIR}/tools/pack/chips/sun8iw7p1/bin/u-boot-sun8iw7p1.bin ]; then
		echo "u-boot-sun8iw7p1.bin was previously created"
	else
		echo "Building U-Boot legacy"
		if [ -d ${LOBOSRCDIR}/tools/pack/chips/sun8iw7p1/bin ]; then
			rm -f ${LOBOSRCDIR}/tools/pack/chips/sun8iw7p1/bin/u-boot*
			echo "Folder ${SRCFOLDER}/tools/pack/chips/sun8iw7p1/bin has been cleaned"
		else
			mkdir -p ${LOBOSRCDIR}/tools/pack/chips/sun8iw7p1/bin
			echo "Folder ${SRCFOLDER}/tools/pack/chips/sun8iw7p1/bin has been created"
		fi
		LCC=`pwd`/${LOBOSRCDIR}/brandy/gcc-linaro/bin
		export PATH="${LCC}":"$PATH"
		CROSS_COMP=arm-linux-gnueabi
				
		HERE=`pwd`
		cd ${LOBOSRCDIR}/brandy/u-boot-2011.09
			make ARCH=arm mrproper
			echo "make ARCH=arm CROSS_COMPILE=${CROSS_COMP}- sun8iw7p1_config"
			make ARCH=arm CROSS_COMPILE=${CROSS_COMP}- sun8iw7p1_config
			if [ $? -gt 0 ]; then
				myexit 8 "error cross-compiling config file"
			fi
			make ARCH=arm CROSS_COMPILE=${CROSS_COMP}-

			if [ $? -gt 0 ]; then
				myexit 7 "error cross-compiling"
			fi
		cd $HERE
	fi
}

# http://linux-sunxi.org/H3_Manual_build_howto
patch_uboot() {
	if [ ! -f ${LOBOSRCDIR}/tools/pack/chips/sun8iw7p1/bin/u-boot-sun8iw7p1.bin ]; then
		myexit 9 "No ${LOBOSRCDIR}/tools/pack/chips/sun8iw7p1/bin/u-boot-sun8iw7p1.bin file!"
	fi
	if [ ! -f ${OUTDIR}/sys_config.bin ]; then
		myexit 10 "No ${OUTDIR}/sys_config.bin file!"
	fi

	echo "Copy u-boot"
	cp ${LOBOSRCDIR}/tools/pack/chips/sun8iw7p1/bin/u-boot-sun8iw7p1.bin ${OUTDIR}/u-boot.fex
	echo "Patch u-boot"
	${LOBOSRCDIR}/pctools/linux/mod_update/update_uboot ${OUTDIR}/u-boot.fex ${OUTDIR}/sys_config.bin
}

build_kernel () {
	if [ -d ${SRCFOLDER}/output ]; then
		echo "OrangePi+ kernel seems to have been compiled ..."
	else
		echo "Building OrangePi+ kernel..."
		(cd $SRCFOLDER ; ./mybuild.sh)
	fi
}

# http://linux-sunxi.org/H3_Manual_build_howto Installing onto Storage -> SD card
# Secondary program loader + u-Boot
write_initial_SPL_uBoot () {
	SPLFILE="${OUTDIR}/u-boot.fex"
	if [ ! -f $SPLFILE ]; then
		myexit 1 "Cannot find SPL file $SPLFILE - exiting..."
	fi
	# write boot0
	dd if=${OUTDIR}/boot0_sdcard.fex of=$1 bs=1k seek=8
	if [ $? -gt 0 ]; then
		myexit 6 "Dumping ${OUTDIR}/boot0_sdcard.fex file to $1 error - exiting..."
	fi
	echo "boot0 (${OUTDIR}/boot0_sdcard.fex) has been written on $1 after first 8k"
	# write u-boot
	dd if=$SPLFILE of=$1 bs=1k seek=16400
	if [ $? -gt 0 ]; then
		myexit 7 "Dumping SPL file $SPLFILE to $1 error - exiting..."
	fi
	echo "Secondary program loader (${SPLFILE}) has been written on $1 after first 16M"
	
}

# Partition the card with a 100MB boot partition starting at 1MB (type = c = fwin95)
# and the rest as root partition (type = L = linux) 
partition () {
	echo "Partitioning SD card file $1"
fdisk $1 << EOT
n
p
1
2048
+100M
t
c
n
p



w
EOT
}

format() {
	LOOPDEV=`losetup -f --show $1`
	echo "Loop device is $LOOPDEV"
	sudo kpartx -av $LOOPDEV
	BASELDEV=`echo $LOOPDEV | cut -d '/' -f3`
	mkfs.vfat -n BOOT  /dev/mapper/${BASELDEV}p1
	mkfs.ext4 -L Linux /dev/mapper/${BASELDEV}p2
	sudo kpartx -dv $LOOPDEV
	losetup -d $LOOPDEV
}

copy_file() {
	if [ -f $1 ]; then
		echo "Copying $1 to $2"
		sudo cp $1 $2
	else
		echo "File $1 not found"
	fi
}

copy_boot_partition() {
	LOOPDEV=`losetup -f --show $SD_CARD_FILE`
	echo "Loop device is $LOOPDEV"
	sudo kpartx -av $LOOPDEV
	BASELDEV=`echo $LOOPDEV | cut -d '/' -f3`
	sudo mount /dev/mapper/${BASELDEV}p1 $TMPF
	copy_file boot.scr $TMPF
	rm boot.scr
	#copy_file fex $TMPF
	copy_file ${SRCFOLDER}/output/uImage $TMPF
	grep -v "^;" ${OUTDIR}/sys_config.fex | grep -v "^#" > script.fex
	perl -pi -e 's|^max_freq.*|max_freq = 1100000000|g' script.fex
	fex2bin script.fex script.bin
	copy_file script.fex $TMPF
	copy_file script.bin $TMPF
	rm -f script.*
	sudo sync
	#
	echo "Boot partition OK:"
	ls -alF $TMPF
	sudo umount $TMPF
	if [ $? -gt 0 ]; then
		myexit 2 echo "Error unmounting $TMPF"
	fi
	sudo kpartx -dv $LOOPDEV
	losetup -d $LOOPDEV
}

make_uboot_commands () {
	echo "Creating boot.cmd file"
	cat << EOF > boot.cmd
setenv bootargs console=ttyS0 root=/dev/mmcblk0p1 rootwait panic=10 ${extra}
ext2load mmc 0 0x43000000 boot/script.bin
ext2load mmc 0 0x48000000 boot/uImage
bootm 0x48000000
EOF
	echo "Converting boot.cmd -> boot.scr"
	mkimage -C none -A arm -T script -n "OrangePi+" -d boot.cmd boot.scr
}

copy_root_partition() {
	LOOPDEV=`losetup -f --show $SD_CARD_FILE`
	echo "Loop device is $LOOPDEV"
	sudo kpartx -av $LOOPDEV
	BASELDEV=`echo $LOOPDEV | cut -d '/' -f3`
	sudo mount /dev/mapper/${BASELDEV}p2 $TMPF
	#
	sudo cp -r ${SRCFOLDER}/output/lib $TMPF
	sudo mkdir ${TMPF}/boot
	sudo cp ${SRCFOLDER}/output/*-* ${TMPF}/boot
	#
	distro="jessie"
	echo "Loading Debian $distro distribution"
	sudo debootstrap --include=openssh-server,bash --arch=armhf --foreign $distro $TMPF
	if [ $? -gt 0 ]; then
		echo "Error creating Debian distribution"
	else
		echo "nameserver 127.0.1.1" | sudo tee ${TMPF}/etc/resolv.conf
		sudo sh -c "echo 'orangepiplus' >  ${TMPF}/etc/hostname"
		cat <<EOT > /tmp/sources.list
deb http://http.debian.net/debian $distro main contrib non-free
deb-src http://http.debian.net/debian $distro main contrib non-free
deb http://http.debian.net/debian $distro-updates main contrib non-free
deb-src http://http.debian.net/debian $distro-updates main contrib non-free
deb http://security.debian.org/debian-security $distro/updates main contrib non-free
deb-src http://security.debian.org/debian-security $distro/updates main contrib non-free
EOT
		sudo cp -f /tmp/sources.list ${TMPF}/etc/apt/
		echo "Setting password $ROOTPWD -> should be in an ARM chrooted environment"
		#sudo chroot ${TMPF} /bin/bash -c "(echo $ROOTPWD;echo $ROOTPWD;) | passwd root"
		echo "Debian loaded"
	fi
	#
	sudo sync
	#
	echo "Linux partition OK:"
	ls -alF $TMPF
	sudo umount $TMPF
	if [ $? -gt 0 ]; then
		myexit 3 "Error unmounting $TMPF"
	fi
	sudo kpartx -dv $LOOPDEV
	losetup -d $LOOPDEV
}
	
make_sd_card () {
	if [ -f $SD_CARD_FILE ]; then
		echo "SD card file $SD_CARD_FILE exists, won't overwrite..."
	else
		dd if=/dev/zero of=${SD_CARD_FILE} bs=1M count=1
		write_initial_SPL_uBoot ${SD_CARD_FILE}
		dd if=/dev/zero bs=1M count=1600 of=${SD_CARD_FILE} oflag=append conv=notrunc
		#>> ${SD_CARD_FILE}
		echo "1.6 G added at the end of ${SD_CARD_FILE}"
		partition ${SD_CARD_FILE}
		echo "${SD_CARD_FILE} has been partitioned"
		format ${SD_CARD_FILE}
		echo "${SD_CARD_FILE} has been formated"
		make_uboot_commands
		copy_boot_partition
		copy_root_partition
	fi
}

check_exec () {
	which $1 > /dev/null
	if [ $? -gt 0 ]; then
		myexit 4 "$1 not found ... exiting"
	fi
}

check_group() {
	id | grep $1 >/dev/null
	if [ $? -gt 0 ]; then
		myexit 5 "User does not belong to group $1 ... exiting"
	fi
}

check_requirements() {
	echo "Checking requirements for building..."
	if [ "`arch`" -ne "x86_64" ]; then
		myexit 7 "Bad architecture..."
	fi
	# kpartx mount.vfat losetup, dd,...
	check_exec dd
	check_exec losetup
	check_exec kpartx
	check_exec mkfs.vfat
	check_exec mkfs.ext4
	check_exec debootstrap
	#check_exec cdebootstrap
	check_exec chroot
	check_exec unix2dos
	check_group disk
	check_group sudo
	echo "Good - all requirements are fullfiled!"
}

build_all () {
	check_requirements
	get_sources
	build_kernel
	build_bin
	if [ ! -f ${LOBOSRCDIR}/tools/pack/chips/sun8iw7p1/bin/u-boot-sun8iw7p1.bin ]; then
		build_uboot_legacy
	fi
	build_fex_script
	#
	patch_uboot
	#
	make_sd_card
	#
	echo "Now you may do, as root"
	echo "dd if=sdcard.img of=/dev/sdd bs=1M oflag=direct"
}

build_all
