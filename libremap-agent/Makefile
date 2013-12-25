#
# Copyright 2013 Patrick Grimm <patrick@lunatiki.de>
# Copyright 2013 André Gaul <gaul@web-yard.de>
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-lib-libremap
PKG_RELEASE:=0.1.2
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/luci-lib-libremap/default
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=8. Libraries
  URL:=https://github.com/libremap/libremap-agent-openwrt
endef

define Package/luci-lib-libremap
  $(call Package/luci-lib-libremap/default)
  DEPENDS:=+luci-lib-core +luci-lib-json +luci-lib-httpclient +libuci-lua
  TITLE:=LibreMap router database and map library
endef

define Package/luci-lib-libremap-olsr
  $(call Package/luci-lib-libremap/default)
  DEPENDS:=+luci-lib-libremap
  TITLE:=LibreMap router database and map olsr support
endef

define Package/libremap-agent
  SECTION:=utilities
  CATEGORY:=Utilities
  URL:=https://github.com/libremap/libremap-agent-openwrt
  TITLE:=LibreMap router database and map submit agent
  DEPENDS:=+luci-lib-libremap
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./luasrc $(PKG_BUILD_DIR)/
endef

define Build/Compile
	#$(MAKE) -C $(PKG_BUILD_DIR)/luasrc
endef

define Package/luci-lib-libremap/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/libremap
	$(CP) $(PKG_BUILD_DIR)/luasrc/libremap.lua $(1)/usr/lib/lua/luci/
	$(CP) $(PKG_BUILD_DIR)/luasrc/libremap/util.lua $(1)/usr/lib/lua/luci/libremap/
endef

define Package/luci-lib-libremap-olsr/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/libremap/plugins
	$(CP) $(PKG_BUILD_DIR)/luasrc/libremap/plugins/olsr.lua $(1)/usr/lib/lua/luci/libremap/plugins
endef

define Package/libremap-agent/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

# register cronjob
define Package/libremap-agent/postinst
#!/bin/sh
if [ -z $${IPKG_INSTROOT} ] ; then
	( . /etc/uci-defaults/libremap-agent ) && rm -f /etc/uci-defaults/libremap-agent
fi
endef

# unregister cronjob
define Package/libremap-agent/prerm
#!/bin/sh
if [ -z $${IPKG_INSTROOT} ] ; then
	sed -ie '/libremap-agent/d' /etc/crontabs/root
fi
endef

$(eval $(call BuildPackage,luci-lib-libremap))
$(eval $(call BuildPackage,luci-lib-libremap-olsr))
$(eval $(call BuildPackage,libremap-agent))
