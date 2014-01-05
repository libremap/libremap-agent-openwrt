--[[

Copyright 2013 Patrick Grimm <patrick@lunatiki.de>
Copyright 2013-2014 André Gaul <gaul@web-yard.de>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

]]--

local json = require 'luci.json'
local nixio = require 'nixio'
local string = require 'string'
local uci = (require 'uci').cursor()
local utl = require 'luci.util'

local libremap = require 'luci.libremap'
local util = require 'luci.libremap.util'


-- get jsoninfo
function fetch_jsoninfo(ip, port, cmd)
    local resp = utl.exec('echo /'..cmd..' | nc '..ip..' '..port)
    return json.decode(resp)
end

-- reverse lookup with stripping of mid.
function lookup_olsr_ip(ip, version)
    if version==4 then
        local inet = 'inet'
    elseif version==6 then
        local inet = 'inet6'
    else
        error('ip version '..version..' unknown.')
    end
    -- get name
    local name = nixio.getnameinfo(ip, inet)
    if name ~= nil then
        -- remove 'midX.' from name
        return string.gsub(name, 'mid[0-9]*\.', '')
    else
        return nil
    end
end

-- get links for specified ip version (4 or 6)
function fetch_links(version)
    local ip
    local type
    -- set variables that depend on ip version
    if version==4 then
        ip = '127.0.0.1' -- for jsoninfo
        type = 'olsr4'   -- type of alias/link
    elseif version==6 then
        ip = '::1'
        type = 'olsr6'
    else
        error('ip version '..version..' unknown.')
    end

    -- retrieve data from jsoninfo
    local jsoninfo = fetch_jsoninfo(ip, '9090', 'links')
    if not jsoninfo or not jsoninfo.links then
        return {}, {}
    end
    local olsr_links = jsoninfo.links

    -- init return values
    local aliases = {}
    local links = {}

    -- step through olsr_links
    for _, link in ipairs(olsr_links) do
        local ip_local = link['localIP']
        local ip_remote = link['remoteIP']
        -- unused at the moment:
        --local name_local = lookup_olsr_ip(ip_local, version)
        --local name_remote = lookup_olsr_ip(ip_remote, version)

        -- insert aliases
        aliases[ip_local] = 1

        -- process link quality
        local quality = link['linkQuality']
        -- TODO: process quality properly
        if quality<0 then
            quality = 0
        elseif quality>1 then
            quality = 1
        elseif not (quality>=0 and quality<=1) then
            quality = 0
        end

        -- insert links
        links[#links+1] = {
            type = type,
            alias_local = ip_local,
            alias_remote = ip_remote,
            quality = quality,
            attributes = link
        }
    end

    -- fill in aliases
    local aliases_arr = {}
    for alias, _ in pairs(aliases) do
        aliases_arr[#aliases_arr+1] = {
            type = type,
            alias = alias
        }
    end
    return aliases_arr, links
end

-- appent array b to array a
function append(a, b)
    local a = a or {}
    for _, v in ipairs(b) do
        a[#a+1] = v
    end
    return a
end

-- insert olsr info into doc
function insert(doc)
    -- init fields in doc (if not yet present)
    doc.aliases = doc.aliases or {}
    doc.links = doc.links or {}

    -- get used ip version(s) from config
	local IpVersion = uci:get_first("olsrd", "olsrd","IpVersion")
    local versions = {}
    if IpVersion == '4' then
        versions = {4}
    elseif IpVersion == '6' then
        versions = {6}
    elseif IpVersion == '6and4' then
        versions = {6, 4}
    end

    -- fetch links for used ip versions
    for _, version in pairs(versions) do
        local aliases, links = fetch_links(version)
        append(doc.aliases, aliases)
        append(doc.links, links)
    end
end

return {
    insert = insert
}
