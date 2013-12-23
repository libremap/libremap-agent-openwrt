#
# Copyright 2013 Patrick Grimm <patrick@lunatiki.de>
# Copyright 2013 André Gaul <gaul@web-yard.de>
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-libremap
PKG_RELEASE:=0.1.0
PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-libremap/default
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  MAINTAINER:=André Gaul <gaul@web-yard.de>
  URL:=https://github.com/libremap/libremap-agent-openwrt
endef

define Package/luci-lib-libremap
  $(call Package/luci-app-libremap/default)
  DEPENDS:=+luci-lib-core +luci-lib-json +luci-lib-httpclient +libuci-lua
  TITLE:=LibreMap router database and map (library)
endef

define Package/luci-app-libremap
  $(call Package/luci-app-libremap/default)
  DEPENDS:=+luci-lib-libremap
  TITLE:=LibreMap router database and map (submit agent)
endef

define Build/Prepare
  mkdir -p $(PKG_BUILD_DIR)
  $(CP) ./luasrc $(PKG_BUILD_DIR)/
endef

define Build/Compile
  $(MAKE) -C $(PKG_BUILD_DIR)/luasrc
endef

define Package/luci-lib-libremap/install
  $(INSTALL_DIR) $(1)/usr/lib/lua/luci/libremap
  $(CP) $(PKG_BUILD_DIR)/luasrc/libremap.lua $(1)/usr/lib/lua/luci/
  $(CP) $(PKG_BUILD_DIR)/luasrc/libremap/util.lua $(1)/usr/lib/lua/luci/libremap/
endef

define Package/luci-app-libremap/install
  $(INSTALL_DIR) $(1)/usr/sbin
  $(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,luci-lib-libremap))
$(eval $(call BuildPackage,luci-app-libremap))
