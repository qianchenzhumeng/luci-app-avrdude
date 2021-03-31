#
# Copyright (C) 2021 前尘逐梦 <qianchenzhumeng@live.cn>
#
# This is free software, licensed under the Apache License, Version 2.0 .
#
include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI Support for avrdude
LUCI_DEPENDS:=+avrdude

include ../../luci.mk

# call BuildPackage - OpenWrt buildroot signature

