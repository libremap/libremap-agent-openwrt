--[[

Copyright 2013 Nicolás Echániz <nicoechaniz@altermundi.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

]]--

local netm = require "luci.model.network"

-- TODO: this hardcoded values could be set in the config for the plugin
-- the current chosen thresholds are Ubiquiti's default for led signal indicator
local function link_quality(signal)
   if signal >= -65 then
      return 1
   elseif signal >= -73 then
      return 0.75
   elseif signal >= -80 then
      return 0.5
   elseif signal >= -90 then
      return 0.25
   else
      return 0.1
   end
end

local function clean_aliases(doc)
   if doc.aliases ~= nil then
      for i, alias in ipairs(doc.aliases) do
         if alias.type == "wifi" then
            table.remove(doc.aliases, i)
         end
      end
   end
end

local function read_wifilinks()
   local ntm = netm.init()
   local wifidevs = ntm:get_wifidevs()
   local wifilinks = {}
   local macs = {}
   for _, dev in ipairs(wifidevs) do
      for _, net in ipairs(dev:get_wifinets()) do
         local local_mac = string.upper(ntm:get_interface(net.iwdata.ifname).dev.macaddr)
         local channel = net:channel()
         local assoclist = net.iwinfo.assoclist or {}
         for station_mac, link_data in pairs(assoclist) do
            local wifilink = {
               type = "wifi",
               alias_local = local_mac,
               alias_remote = station_mac,
               quality = link_quality(link_data.signal),
               attributes = {
                  interface = net.iwdata.ifname,
                  local_mac = local_mac,
                  station_mac = station_mac,
                  channel = channel,
                  signal = link_data.signal
               }
            }
            table.insert(wifilinks, wifilink)
         end
         table.insert(macs, local_mac)
      end
   end
   return macs, wifilinks
end

function insert(doc)
   local macs, wifilinks
   macs, wifilinks = read_wifilinks()

-- clean the existing wifi aliases from the document
   clean_aliases(doc)
   local aliases = {}

   for _, mac in ipairs(macs) do
      table.insert(aliases, {type = "wifi", alias = mac})
   end

-- if aliases is not empty, insert aliases and wifilinks data in the doc
   if next(aliases) ~= nil then
      doc.links = wifilinks
      doc.aliases = aliases
   end
end

return {
    insert = insert
}
