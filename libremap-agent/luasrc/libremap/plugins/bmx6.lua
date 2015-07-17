--[[

Copyright 2015 Nicolás Echániz <nicoechaniz@altermundi.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

]]--

local json = require "luci.json"

function concat_tables(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end

local function read_file(file_path)
    local f = assert(io.open(file_path, "r"))
    local c = f:read "*a"
    f:close()
    return c
end

local function clean_aliases(doc)
   if doc.aliases ~= nil then
      for i, alias in ipairs(doc.aliases) do
         if alias.type == "bmx6" then
            table.remove(doc.aliases, i)
         end
      end
   end
end

local function read_bmx6links()
    local bmx6links = {}
    local links_data = json.decode(read_file("/var/run/bmx6/json/links")).links
    local interfaces_data = json.decode(read_file("/var/run/bmx6/json/interfaces")).interfaces
    local llocalIps = {}

    for _, interface_data in pairs(interfaces_data) do
        if interface_data.state ~= "DOWN" then
            local llIp = string.sub(interface_data.llocalIp, 0, -4)
            table.insert(llocalIps, llIp)
        end
    end

    for _, link_data in pairs(links_data) do
        local remote_ip = link_data.llocalIp
        for _, interface_data in pairs(interfaces_data) do
            if interface_data.devName == link_data.viaDev then
                local_ip = string.sub(interface_data.llocalIp, 0, -4)
            end
        end
        local link = {
            type = "bmx6",
            alias_local = local_ip,
            alias_remote = remote_ip,
            quality = link_data.rxRate/100,
            attributes = {
                name = link_data.name,
                rxRate = link_data.rxRate,
                viaDev = link_data.viaDev,
            }
        }
        table.insert(bmx6links, link)
    end
    return llocalIps, bmx6links
end

function insert(doc)
   local llocalIps, bmx6links
   llocalIps, bmx6links = read_bmx6links()

-- clean the existing bmx6 aliases from the document
   clean_aliases(doc)
   local aliases = {}

   for _, llocalIp in ipairs(llocalIps) do
      table.insert(aliases, {type = "bmx6", alias = llocalIp })
   end

-- if aliases is not empty, insert aliases and bmx6links data in the doc
   if next(aliases) ~= nil then
       if doc["links"] ~= nil then
           concat_tables(doc.links, bmx6links)
       else
           doc.links = bmx6links
       end
       if doc["aliases"] ~= nil then
           concat_tables(doc.aliases, aliases)
       else
           doc.aliases = aliases
       end
   end
end

return {
    insert = insert
}

