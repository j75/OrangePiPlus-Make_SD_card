#!/bin/sh

# ./OrangePI-Kernel/build/config.good/sun8iw7p1smp_lobo_defconfig.opiplus

TMPDIR=`mktemp -d /tmp/XXXOPI_$$`
CURD=`pwd`
OUTFOLDER=build
SRCFOLDER=OrangePiPlus-Kernel
LOBOSRCDIR=${SRCFOLDER}/OrangePI-Kernel
SD_CARD_FILE=./nsdcard.img
ROOTPWD="toor" # Must be changed @ first login

end()
{
	echo "Deleting $TMPDIR"
        sudo rm -rf $TMPDIR
        exit 0
}

trap end 9 2

get_sources() {
	if [ -d $SRCFOLDER ]; then
		echo "Git source folder ${SRCFOLDER} exists, updating ..."
		(cd $SRCFOLDER ; git pull)
	else
		git clone https://github.com/j75/OrangePiPlus-Kernel.git
	fi

	if [ -d u-boot ]; then
		echo "Git u-boot folder exists, updating ..."
		(cd u-boot ; git pull)
	else
		git clone git://git.denx.de/u-boot.git
	fi
}

build_fex_script() {
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

		build_fex_script "OPI-PLUS" "720p50" "hdmi"
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
			# TODO -DCONFIG_SYS_BOOTM_LEN=0xF00000
			echo "Preventing 'Image too large: increase CONFIG_SYS_BOOTM_LEN'"
			perl -pi -e 's|^#define CONFIG_SYS_BOOTM_LEN.*|#define CONFIG_SYS_BOOTM_LEN    0xFFF000|' ./u-boot/common/bootm.c
			cd u-boot
			make ARCH=arm mrproper
			echo "make CROSS_COMPILE=${CROSS_COMP}- orangepi_plus_defconfig"
			make CROSS_COMPILE=${CROSS_COMP}- orangepi_plus_defconfig
			echo "make CROSS_COMPILE=${CROSS_COMP}-"
			#make CROSS_COMPILE=${CROSS_COMP}- V=1
			make CROSS_COMPILE=${CROSS_COMP}-
			RES_COMP_UBOOT=$?
			git checkout common/bootm.c
			if [ $RES_COMP_UBOOT -gt 0 ]; then
				echo "Error building u-boot"
				exit 9
			else
				echo "OK u-boot creation"
				ls -alF u-boot-sunxi-with-spl.bin u-boot
			fi
			cd ..
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
	echo "Secondary program loader and u-Boot (u-boot-sunxi-with-spl.bin)"
    echo "    have been written on $1 after first 8k"	
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
	mkfs.ext2 -L BOOT  /dev/mapper/${BASELDEV}p1
	if [ $? -gt 0 ]; then
		echo "Error formating /dev/mapper/${BASELDEV}p1"
		sudo kpartx -dv $LOOPDEV
		losetup -d $LOOPDEV
		exit 7
	fi
	FORMATP2=""
	mkfs.ext4 -L Linux /dev/mapper/${BASELDEV}p2
	if [ $? -gt 0 ]; then
		echo "Error formating /dev/mapper/${BASELDEV}p2"
		FORMATP2="ko"
	fi
	sudo kpartx -dv $LOOPDEV
	losetup -d $LOOPDEV
	if [ -n $ FORMATP2 ]; then
		exit 8
	fi
}

copy_file() {
	if [ -f $1 ]; then
		echo "Copying $1 to $2"
		sudo cp $1 $2
	else
		echo "File $1 not found"
	fi
}

convert_fex2bin ()
{
	grep -v "^;" ${OUTFOLDER}/sys_config.fex | grep -v "^#" > script.fex
	# max. frequency: 1.2 GHz
	perl -pi -e 's|^extremity_freq.*|extremity_freq = 1200000000|g' script.fex
	#perl -pi -e 's|^max_freq.*|max_freq = 1100000000|g' script.fex
	echo "Converting script.fex -> script.bin"
	fex2bin script.fex script.bin
}

copy_boot_partition() {
	LOOPDEV=`losetup -f --show $SD_CARD_FILE`
	echo "Loop device is $LOOPDEV"
	sudo kpartx -av $LOOPDEV
	BASELDEV=`echo $LOOPDEV | cut -d '/' -f3`
	sudo mount /dev/mapper/${BASELDEV}p1 $TMPDIR
	if [ $? -gt 0 ]; then
		echo "Error mounting /dev/mapper/${BASELDEV}p1 -> $TMPDIR"
		sudo kpartx -dv $LOOPDEV
		losetup -d $LOOPDEV
		exit 1
	fi
	copy_file boot.scr $TMPDIR
	rm boot.scr
	#copy_file fex $TMPDIR
	echo "Transferring uImage kernel to SD card boot partition"
	ls -alF ${SRCFOLDER}/output/uImage*
	sudo cp -a ${SRCFOLDER}/output/uImage* $TMPDIR
	#
	convert_fex2bin
	copy_file script.fex $TMPDIR
	copy_file script.bin $TMPDIR
	rm -f script.*
	sudo sync
	#
	echo "Boot partition OK:"
	ls -alF $TMPDIR
	sudo umount $TMPDIR
	if [ $? -gt 0 ]; then
		echo "Error unmounting $TMPDIR"
		exit 2
	fi
	sudo kpartx -dv $LOOPDEV
	losetup -d $LOOPDEV
}

make_uboot_commands () {
	echo "Creating boot.cmd file"
	cat << EOF > boot.cmd
setenv bootargs console=ttyS0 root=/dev/mmcblk0p1 rootwait panic=10 ${extra}
ext2load mmc 0 0x43000000 script.bin
ext2load mmc 0 0x48000000 uImage
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
	sudo mount /dev/mapper/${BASELDEV}p2 $TMPDIR
	if [ $? -gt 0 ]; then
		echo "Error mounting /dev/mapper/${BASELDEV}p2 -> $TMPDIR"
		sudo kpartx -dv $LOOPDEV
		losetup -d $LOOPDEV
		exit 3
	fi
	#
	echo "Transferring ${SRCFOLDER}/output/lib to SD card file"
	sudo cp -r ${SRCFOLDER}/output/lib $TMPDIR
	# rm build/source
	sudo rm -f ${TMPDIR}/lib/modules/*/{build,source}
	#
	sudo mkdir ${TMPDIR}/boot
	echo "Transferring kernel to SD card file root partition"
	ls -alF ${SRCFOLDER}/output/*-*
	sudo cp ${SRCFOLDER}/output/*-* ${TMPDIR}/boot
	#
	sudo cp u-boot/System.map ${TMPDIR}/boot/u-boot-System.map
	#
	distro="jessie"
	echo "Loading Debian $distro distribution"
	sudo debootstrap --include=openssh-server --arch=armhf --foreign $distro $TMPDIR
	if [ $? -gt 0 ]; then
		echo "Error creating Debian distribution"
	else
		echo "nameserver 127.0.1.1" | sudo tee ${TMPDIR}/etc/resolv.conf
		sudo sh -c "echo 'orangepiplus' >  ${TMPDIR}/etc/hostname"
		#
		cat <<EOT > /tmp/sources.list
deb http://http.debian.net/debian $distro main contrib non-free
#deb-src http://http.debian.net/debian $distro main contrib non-free

deb http://http.debian.net/debian $distro-updates main contrib non-free
#deb-src http://http.debian.net/debian $distro-updates main contrib non-free

deb http://security.debian.org/debian-security $distro/updates main contrib non-free
#deb-src http://security.debian.org/debian-security $distro/updates main contrib non-free
EOT
		sudo cp -f /tmp/sources.list ${TMPDIR}/etc/apt/
		#
		sudo rm -rf ${TMPDIR}/debootstrap
		echo "Setting password $ROOTPWD -> should be in an ARM chrooted environment"
		#sudo chroot ${TMPDIR} /bin/bash -c "(echo $ROOTPWD;echo $ROOTPWD;) | passwd root"
		sudo sh -c "echo 'root:x:0:0:root:/root:/bin/bash' >  ${TMPDIR}/etc/passwd"
		sudo sh -c "echo 'daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin' >>  ${TMPDIR}/etc/passwd"
		sudo sh -c "echo 'bin:x:2:2:bin:/bin:/usr/sbin/nologin' >>  ${TMPDIR}/etc/passwd"
		sudo sh -c "echo 'sys:x:3:3:sys:/dev:/usr/sbin/nologin' >>  ${TMPDIR}/etc/passwd"
		sudo sh -c "echo 'nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin' >>  ${TMPDIR}/etc/passwd"
		sudo sh -c "echo 'root:\$6\$j3USIojv\$Vc1VrKa3j0MKXaLrEZyc2w3PnbRpBIPmt0ULvnIqquMPkWKW1fim4PBn.m0iC5BaZq609o27x3TIp8D0GKKBj/:16882:0:99999:7:::' >>  ${TMPDIR}/etc/shadow"
		sudo chmod 640 ${TMPDIR}/etc/shadow
		#
		echo "Debian loaded"
	fi
	#
	sudo sync
	#
	echo "Linux partition OK:"
	ls -alF $TMPDIR
	sudo umount $TMPDIR
	if [ $? -gt 0 ]; then
		echo "Error unmounting $TMPDIR"
		exit 4
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
		exit 5
	else
		echo "  $1 exists ... good!"
	fi
}

check_group() {
	id | grep $1 >/dev/null
	if [ $? -gt 0 ]; then
		echo "User does not belong to group $1 ... exiting"
		exit 6
	else
		echo "  user belongs to group $1 ... good!"
	fi
}

check_requirements() {
	echo "Checking requirements for building..."
	# kpartx mount.vfat losetup, dd,...
	check_exec dd
	check_exec chmod
	check_exec losetup
	check_exec kpartx
	check_exec mkfs.ext2
	check_exec mkfs.ext4
	check_exec debootstrap
	#check_exec cdebootstrap
	check_exec chroot
	check_exec perl
	check_exec fex2bin
	check_group disk
	check_group sudo
	echo "All requirements are fullfiled!"
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
