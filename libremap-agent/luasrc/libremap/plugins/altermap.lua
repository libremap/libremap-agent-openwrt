--[[

Copyright 2013 Nicolás Echániz <nicoechaniz@altermundi.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

]]--

local httpc = require "luci.httpclient"
local json = require "luci.json"
local uci = require "uci"
local uci = uci.cursor()

local function read_hostname()
   local hostname
   uci:foreach("system", "system",
               function(s)
                  hostname = uci:get("system", s[".name"], "hostname")
                  return false
               end)
   return hostname
end

local function retrieve_network_data(network_name)
   local server_url = uci:get("altermap", "agent", "server_url")
   local json_string = json.encode({keys={network_name}})
   local res = httpc.request_to_buffer(
      server_url.."/_design/altermap/_view/networkByName",
      {headers={["Content-Type"]="application/json"}, method="POST", body=json_string})
   return json.decode(res)
end

local function retrieve_node_data(network_id, node_name)
   local server_url = uci:get("altermap", "agent", "server_url")
   local json_string = json.encode({keys={{network_id, node_name}}})
   local res = httpc.request_to_buffer(
      server_url.."/_design/altermap/_view/nodeByNetIdAndName",
      {headers={["Content-Type"]="application/json"}, method="POST", body=json_string})
   return json.decode(res)
end

function insert(doc)

   local network_name = uci:get("altermap", "agent", "network")
   local network = retrieve_network_data(network_name)
   if not network then
      print("err", "error: could not retrieve network data from AlterMap database")
      return
   end
   local network_id = network.rows[1].id
   doc.community = network_name

   local hostname = read_hostname()
   local node_data = retrieve_node_data(network_id, hostname)
   local altermap_node = node_data.rows[1].value

   if not altermap_node then
      print("err", "error: could not retrieve node data from AlterMap database")
      return
   end

   local lat = altermap_node.coords.lat
   local lon = altermap_node.coords.lon

-- add location data to the doc and save it to the LibreMap config
   doc.lat = lat
   doc.lon = lon
   uci:tset('libremap', 'location', {latitude=lat, longitude=lon})

-- data has been imported, so we disable altarmap plugin
   uci:set('libremap', 'altermap', 'enabled', 0)
   uci:commit('libremap')
end


local altermap_section = uci:get_first('altermap', 'altermap')
if altermap_section ~= nil then
   return {
      insert = insert
   }
end
