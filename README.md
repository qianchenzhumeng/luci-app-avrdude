1. Copy this directory to "feeds/luci/applications/luci-app-avrdude".
2. update & install feeds

```bash
./scripts/feeds update luci
./scripts/feeds install -a -p luci
```

The output message should be:

> Installing all packages from feed luci.
> Installing package 'luci-app-avrdude' from luci

3. make menuconfig

Add luci-app-avrdude and kmod-usb-acm(for Arduino UNO R3):

```
Prompt: luci-app-avrdude........... LuCI Support for avrdude
Location:
    -> LuCI
        -> 3. Applications
```

```
Prompt: kmod-usb-acm.... Support for modems/isdn controllers
Location:
    -> Kernel modules
        -> USB Support
```

4. make
5. Update firmware.

This project is based on [使用OpenWRT路由远程给Arduino下载程序](https://www.geek-workshop.com/thread-5816-1-1.html).

