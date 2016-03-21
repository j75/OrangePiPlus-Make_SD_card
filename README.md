# OrangePi+ bootable image creation

The created image file (**sdcard.img**) is suitable for a SD card.

## References
  * [Orange Pi Main Page](http://www.orangepi.org/Docs/mainpage.html)
  * [Making a bootable .img image file](http://www.orangepi.org/Docs/Makingabootable.html)
  * [Building u-boot, script.bin and linux-kernel](http://www.orangepi.org/Docs/Building.html)
  * OpenWRT [Allwinner Sun4i/5i/6i/7i/9i (sunxi)](http://wiki.openwrt.org/doc/hardware/soc/soc.allwinner.sunxi)
  * [Test Orange Pi PC board with lima-memtester using FEL boot](https://github.com/ssvb/lima-memtester/releases)
  * Jef's page about [OrangePI 2](http://moinejf.free.fr/opi2/)
  * [Linux source for Allwinner/Boxchip F20 (sun3i), A10 (sun4i) and A12/A13 (sun5i) SoCs](https://github.com/jwrdegoede/linux-sunxi/tree/sunxi-wip)
  * [Allwinner A1x native u-boot support](https://github.com/jwrdegoede/u-boot-sunxi)
  * [Orange Pi mini 2 : kernel compile](https://www.gitbook.com/book/sunyzero/orange-pi-mini-2-kernel-compile/details) - in Chinese
  * [Building Ubuntu/Debian installation for OrangePI H3 boards using debootstrap](https://github.com/loboris/OrangePi-BuildLinux)
  * Igor Pečovnik's [Armbian build tools](https://github.com/igorpecovnik/lib)
  * [Setting up the Linux distribution root file system](http://www.orangepi.org/Docs/SettinguptheLinux.html)

## Issues
  * <pre>
U-Boot SPL 2016.03-00213-gf8a4826 (Mar 17 2016 - 09:19:54)
DRAM: 1024 MiB
Trying to boot from MMC

U-Boot 2016.03-00213-gf8a4826 (Mar 17 2016 - 09:19:54 +0100) Allwinner Technology

CPU:   Allwinner H3 (SUN8I)
Model: Xunlong Orange Pi Plus
I2C:   ready
DRAM:  1 GiB
MMC:   SUNXI SD/MMC: 0
*** Warning - bad CRC, using default environment

In:    serial
Out:   serial
Err:   serial
Net:   No ethernet found.
starting USB...
USB0:   USB EHCI 1.00
USB1:   USB EHCI 1.00
scanning bus 0 for devices... 1 USB Device(s) found
scanning bus 1 for devices... 1 USB Device(s) found
Hit any key to stop autoboot:  2 0
switch to partitions #0, OK
mmc0 is current device
Scanning mmc 0:1...
Found U-Boot script /boot.scr
reading /boot.scr
238 bytes read in 19 ms (11.7 KiB/s)
\## Executing script at 43100000
Failed to mount ext2 filesystem...
** Unrecognized filesystem type ** 
</pre>
