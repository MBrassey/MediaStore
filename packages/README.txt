HPTAccelerate Linux Open Source package
User guide
Copyright (C) 2022 HighPoint Technologies, Inc. All rights reserved.

1. Overview
2. File list
3. Instructions for use
4. Revision history
5. Technical support and service

#############################################################################
1. Overview
#############################################################################

  This package contains Linux shell program. You can use it to improve the 
  performance of HighPoint RAID devices by binding cpu cores.

  NO WARRANTY

  THE SOURCE CODE HIGHPOINT PROVIDED IS FREE OF CHARGE, AND THERE IS
  NO WARRANTY FOR THE PROGRAM. THERE ARE NO RESTRICTIONS ON THE USE OF THIS
  FREE SOURCE CODE. HIGHPOINT DOES NOT PROVIDE ANY TECHNICAL SUPPORT IF THE
  CODE HAS BEEN CHANGED FROM ORIGINAL SOURCE CODE.

  LIMITATION OF LIABILITY

  IN NO EVENT WILL HIGHPOINT BE LIABLE FOR DIRECT, INDIRECT, SPECIAL,
  INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OF OR
  INABILITY TO USE THIS PRODUCT OR DOCUMENTATION, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGES. IN PARTICULAR, HIGHPOINT SHALL NOT HAVE
  LIABILITY FOR ANY HARDWARE, SOFTWARE, OR DATA STORED USED WITH THE
  PRODUCT, INCLUDING THE COSTS OF REPAIRING, REPLACING, OR RECOVERING
  SUCH HARDWARE, OR DATA.

#############################################################################
2. File list
#############################################################################

  |- README                         : this file
  `- HPTAccelerate.sh               : shell for improving the performance of 
                                      HighPoint RAID devices

#############################################################################
3. Instructions for use
#############################################################################

  HPTAccelerate.sh is used to improve the performance of HighPoint RAID devices.
  It can bind a specified number of CPU cores on a single CPU
  to the HighPoint RAID device to reduce losses and improve performance.
  Can only accelerate operations that are running or about to
  start running on the HighPoint RAID devices.

  Prerequisites:
    1.Server platform with multiple cpus
    2.Insert HighPoint RAID controller
    3.Load HighPoint RAID driver

  ./HPTAccelerate.sh [options] <command>
    -c                          Specify the number of cpu cores.
    -d                          Specify device name(hptnvme, rr3740a).
    -h, --help                  Print this message and exit.

  For example:
  If you want to copy /test/a to /test/b(cp -r /test/a /test/b)
  and want to bind 4 cpu cores on hptnvme:
  ./HPTAccelerate.sh -c 4 -d hptnvme cp -r /test/a /test/b

  If you want to run kdenlive
  and bind 8 cpu cores on rr3740a:
  ./HPTAccelerate.sh -c 8 -d rr3740a kdenlive

  If you want to run kdenlive and bind all HighPoint RAID
  device's cpu cores on only one device type you have：
  ./HPTAccelerate.sh kdenlive


#############################################################################
4. Revision history
#############################################################################
  v1.0.0
   * Support SSD7000 series.
   * Support binding a specified number of cpu cores or all NVMe local cpu cores.
   
  v1.0.1
   * Support RR3700 series.
        
#############################################################################
5. Technical support and service
#############################################################################

  If you have questions about installing or using your HighPoint product,
  check the user's guide or readme file first, and you will find answers to
  most of your questions here. If you need further assistance, please
  contact us. We offer the following support and information services:

  1)  The HighPoint Web Site provides information on software upgrades,
      answers to common questions, and other topics. The Web Site is
      available from Internet 24 hours a day, 7 days a week, at
      http://www.highpoint-tech.com.

  2)  For technical support, send e-mail to support@highpoint-tech.com and
      attach file /var/log/hptdrv.log if possible.

  NOTE: Before you send an e-mail, please visit our Web Site
        (http://www.highpoint-tech.com) to check if there is a new or 
        updated device driver for your system.

