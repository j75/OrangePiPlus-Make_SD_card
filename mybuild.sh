#!/bin/sh

# @(#)mybuild.sh	1.11 03/21/16

# ./OrangePI-Kernel/build/config.good/sun8iw7p1smp_lobo_defconfig.opiplus

TMPF=`mktemp -d /tmp/XXXOPI_$$`
CURD=`pwd`
OUTFOLDER=build
SRCFOLDER=OrangePiPlus-Kernel
LOBOSRCDIR=${SRCFOLDER}/OrangePI-Kernel
SD_CARD_FILE=./sdcard.img
ROOTPWD="toor" # Must be changed @first login

end()
{
        sudo rm -f $TMPF
        exit 0
}

trap end 9 2

get_sources() {
	if [ -d $SRCFOLDER ]; then
		echo "Source folder ${SRCFOLDER} exists, updating ..."
		(cd $SRCFOLDER ; git pull)
	else
		git clone https://github.com/j75/OrangePiPlus-Kernel.git
	fi

	if [ -d u-boot ]; then
		echo "U-boot folder exists, updating ..."
		(cd u-boot ; git pull)
	else
		git clone git://git.denx.de/u-boot.git
	fi
}

build_script() {
	echo "Building script.bin.${1}_${2}_${3}"

	cp ${LOBOSRCDIR}/build/orange_pi_plus.fex ${OUTFOLDER}/sys_config.fex
	# 720p50
	cat ${OUTFOLDER}/sys_config.fex | sed s/"screen0_output_mode      = 10"/"screen0_output_mode      = 4"/g > ${OUTFOLDER}/_sys_config.fex
	mv ${OUTFOLDER}/_sys_config.fex ${OUTFOLDER}/sys_config.fex
	cat ${OUTFOLDER}/sys_config.fex | sed s/"screen1_output_mode      = 10"/"screen1_output_mode      = 4"/g > ${OUTFOLDER}/_sys_config.fex
	mv ${OUTFOLDER}/_sys_config.fex ${OUTFOLDER}/sys_config.fex
}

build_bin () {
	if [ -d ${OUTFOLDER} ]; then
		echo "Output folder ${OUTFOLDER} exists, ..."
	else
		mkdir ${OUTFOLDER}

		build_script "OPI-PLUS" "720p50" "hdmi"
	fi
}

set_cross_compiler() {
	# arm-linux-gnueabihf-gcc
	CROSS_COMP=arm-linux-gnueabihf
	which ${CROSS_COMP}-gcc >/dev/null
	if [ $? -eq 0 ]; then
		echo -n "Using cross-compiler "
		which ${CROSS_COMP}-gcc
	else
		CROSS_COMP=arm-linux-gnueabi
		which ${CROSS_COMP}-gcc >/dev/null
		if [ $? -gt 0 ]; then
			LCC=`pwd`/OrangePiPlus-Kernel/OrangePI-Kernel/brandy/gcc-linaro/bin
			export PATH="${LCC}":"$PATH"
		else
			echo -n "Using cross-compiler "
			which ${CROSS_COMP}-gcc
		fi
	fi
}

# https://linux-sunxi.org/Mainline_U-boot
build_uboot_new () {
	if [ -f u-boot/u-boot-sunxi-with-spl.bin ]; then
		echo "Good - u-boot-sunxi-with-spl.bin exists"
	else
		echo "Building U-Boot mainline"
		if [ -f u-boot/u-boot-sunxi-with-spl.bin ]; then
			echo "u-boot-sun8iw7p1.bin was previously created"
		else
			set_cross_compiler
			cd u-boot
			make disclean
			echo "make CROSS_COMPILE=${CROSS_COMP}- orangepi_plus_defconfig"
			make CROSS_COMPILE=${CROSS_COMP}- orangepi_plus_defconfig
			make CROSS_COMPILE=${CROSS_COMP}-
		fi
	fi
}

build_kernel () {
	if [ -d ${SRCFOLDER}/output ]; then
		echo "OrangePi+ kernel seems to have been compiled ..."
	else
		echo "Building OrangePi+ kernel..."
		(cd $SRCFOLDER ; ./mybuild.sh)
	fi
}

# Secondary program loader + u-Boot
write_initial_SPL_anduBoot () {
	dd if=./u-boot/u-boot-sunxi-with-spl.bin of=$1 bs=1024 seek=8
	echo "Secondary program loader and u-Boot (u-boot-sunxi-with-spl.bin) have been written on $1 after first 8k"
	
}

# SPL + u-Boot
write_separate () {
	dd if=./u-boot/spl/sunxi-spl.bin of=$1 bs=1024 seek=8 conv=notrunc
	echo "SPL loader u-boot/spl/sunxi-spl.bin has been written on $1"
	dd if=./u-boot/u-boot.bin of=$1 bs=1024 seek=32 conv=notrunc
	echo "Das U-Boot u-boot/u-boot.bin has been written on $1"
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
	grep -v "^;" ${OUTFOLDER}/sys_config.fex | grep -v "^#" > script.fex
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
		echo "Error unmounting $TMPF"
		exit 2
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
		echo "Error unmounting $TMPF"
		exit 3
	fi
	sudo kpartx -dv $LOOPDEV
	losetup -d $LOOPDEV
}
	
make_sd_card () {
	if [ -f $SD_CARD_FILE ]; then
		echo "SD card file $SD_CARD_FILE exists, won't overwrite..."
	else
		dd if=/dev/zero of=${SD_CARD_FILE} bs=1M count=1
		write_initial_SPL_anduBoot ${SD_CARD_FILE}
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
		echo "$1 not found ... exiting"
		exit 4
	fi
}

check_group() {
	id | grep $1 >/dev/null
	if [ $? -gt 0 ]; then
		echo "User does not belong to group $1 ... exiting"
		exit 4
	fi
}

check_requirements() {
	echo "Checking requirements for building..."
	# kpartx mount.vfat losetup, dd,...
	check_exec dd
	check_exec losetup
	check_exec kpartx
	check_exec mkfs.vfat
	check_exec mkfs.ext4
	check_exec debootstrap
	#check_exec cdebootstrap
	check_exec chroot
	check_group disk
	check_group sudo
	echo "Good - all requirements are fullfiled!"
}

build_all () {
	check_requirements
	get_sources
	build_kernel
	build_bin
	if [ ! -f u-boot/u-boot-sunxi-with-spl.bin ]; then
		build_uboot_new
	fi
	#
	make_sd_card
}

build_all
