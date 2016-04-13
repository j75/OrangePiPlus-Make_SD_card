# OrangePi+ bootable image creation

The created image file (**nsdcard.img**) is suitable for a SD card to
run Linux on a OrangePi Plus board.

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
  + boots, but does not load kernel: <keyword>
  ```
HELLO! BOOT0 is starting!
boot0 version : 4.0.0
fel_flag = 0x00000000
rtc[0] value = 0x00000000
rtc[1] value = 0x00000000
rtc[2] value = 0x00000000
rtc[3] value = 0x00000000
rtc[4] value = 0x00000000
rtc[5] value = 0x00000000
rtc[6] value = 0x00000000
rtc[7] value = 0x00000000
DRAM DRIVE INFO: V0.8
DRAM Type = 3 (2:DDR2,3:DDR3,6:LPDDR2,7:LPDDR3)
DRAM CLK = 672 MHz
DRAM zq value: 003b3bfb
READ DQS LCDL = 001c1c1c
DRAM SIZE =1024 M
odt delay 
dram size =1024
card boot number = 0
card no is 0
sdcard 0 line count 4
[mmc]: mmc driver ver 2014-12-10 21:20:39
[mmc]: ***Try SD card 0***
[mmc]: SD/MMC Card: 4bit, capacity: 1876MB
[mmc]: vendor: Man 0002544d Snr 9c100113
[mmc]: product: SA02G
[mmc]: revision: 0.4
[mmc]: ***SD/MMC 0 init OK!!!***
sdcard 0 init ok
The size of uboot is 000dc000.
sum=6f0b4bf6
src_sum=6f0b4bf6
Succeed in loading uboot from sdmmc flash.
Ready to disable icache.
Jump to secend Boot.
SUNXI_NORMAL_MODE   
already secure mode

[      0.349]

U-Boot 2011.09-rc1-00000-g0cc8d85-dirty (Apr 05 2016 - 21:00:55) Allwinner Technology 

[      0.358]version: 1.1.0
normal mode
[      0.365]pmbus:   ready
not set main pmu id
axp_probe error
[      0.380]PMU: pll1 1536 Mhz,PLL6=600 Mhz
AXI=512 Mhz,AHB=200 Mhz, APB1=100 Mhz 
sid read already 
fel key new mode
run key detect
no key found
no key input
dram_para_set start
dram_para_set end
normal mode
[      0.410]DRAM:  1 GiB
relocation Offset is: 35af9000
[box standby] read rtc = 0x0
[box_start_os] mag be start_type no use
user_gpio config
user_gpio ok
gic: normal or no secure os mode
workmode = 0
MMC:	 0
[      0.482][mmc]: mmc driver ver 2014-12-10 9:23:00
[      0.487][mmc]: get sdc_phy_wipe fail.
[      0.491][mmc]: get sdc0 sdc_erase fail.
[      0.495][mmc]: get sdc_f_max fail,use default 50000000Hz
[      0.500][mmc]: get sdc_ex_dly_used fail,use default dly
[      0.506][mmc]: SUNXI SD/MMC: 0
[      0.519][mmc]: *Try SD card 0*
[      0.552][mmc]: CID 0x2544d53 0x41303247 0x49c1001 0x1300a4db
[      0.557][mmc]: mmc clk 50000000
[      0.560][mmc]: SD/MMC Card: 4bit, capacity: 1876MB
[      0.565][mmc]: boot0 capacity: 0KB,boot1 capacity: 0KB
[      0.571][mmc]: ***SD/MMC 0 init OK!!!***
[      0.576][mmc]: erase_grp_size:0x1WrBlk * 0x200 = 0x200 Byte
[      0.582][mmc]: secure_feature 0x0
[      0.585][mmc]: secure_removal_type  0x0
[      0.589]sunxi flash init ok
script config pll_de to 864 Mhz
Not Found clk pll_video1 in script 
script config pll_video to 297 Mhz
[boot]disp_init_tv
[DISP_TV] disp_init_tv enter g_tv_used
screen 0 do not support TV TYPE!
[BOOOT_DISP_TV] disp tv device_registered
unable to find regulator vcc-hdmi-18 from [pmu1_regu] or [pmu2_regu] 
enable power vcc-hdmi-18, ret=-1
DRV_DISP_Init end
boot_disp.auto_hpd=1
auto hpd check has 100 times!
auto check no any connected, the output_type is 4
[disk_read_fs] no the partition
error: open disp_rsl.fex, maybe it is not exist
not support this mode[4], use inline mode[4]
attched ok, mgr0<-->device0, type=4, mode=4----
ready to set mode
[      1.970]finally, output_type=0x4, output_mode=0x4, screen_id=0x0, disp_para=0x0
fail to find part named env
Using default environment

In:    serial
Out:   serial
Err:   serial
--------fastboot partitions--------
mbr not exist
base bootcmd=run setargs_mmc boot_normal
bootcmd set setargs_mmc
key 0
cant find rcvy value
cant find fstbt value
no misc partition is found
to be run cmd=run setargs_mmc boot_normal
[      2.007][mmc]: MMC Device 2 not found
[      2.011][mmc]: Can not find mmc dev
[      2.014][mmc]: read first backup failed in fun sdmmc_secure_storage_read line 1849
sunxi_secstorage_read fail
get secure storage map err
the private part isn't exist
WORK_MODE_BOOT
adver not need show
sunxi_bmp_logo_display
[disk_read_fs] no the partition
error: open bootlogo.bmp, maybe it is not exist
sunxi bmp info error : unable to open logo file bootlogo.bmp
[      2.047]Hit any key to stop autoboot:  5 4 3 2 1 0 
[      7.489][mmc]: Should not w/r secure area in fun mmc_bread_secure,line,1696 in start 2489,end 18936
Error reading cluster

** Unable to read "uimage" from mmc 0:1 **
Wrong Image Format for bootm command
ERROR: can't get kernel image!
sunxi#
```
