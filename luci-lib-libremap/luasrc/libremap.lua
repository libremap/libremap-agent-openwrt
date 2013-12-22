--[[

Copyright 2013 André Gaul <gaul@web-yard.de>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

]]--

local libremap = {}

local fs = require 'luci.fs'
local sys = require 'luci.sys'
local string = require 'string'

local util = require 'libremap.util'


--- Gather data for libremap about this router
function libremap.gather(options)
    options = util.defaults(options, {
        contact = true,
        hash_macs = true,
        hostname = sys.hostname(),
        lat = 52.1, -- TODO
        lon = 13.2  -- TODO
    })

    -- load plugins from libremap/plugins/*.lua
    local plugins = {}
    -- ugly: determine path of this module
    local thisPath = string.sub(debug.getinfo(1).source, 2, -5)
    local files = fs.glob(thisPath..'/plugins/*.lua')
    -- try to load all modules (ignore silently otherwise)
    for _, file in pairs(files) do
        local plugin = string.sub(fs.basename(file), 0, -5)
        util.try(function ()
            plugins[plugin] = require('libremap.plugins.'..plugin)
        end)
    end

    -- create libremap table
    local doc = {
        api_rev = '1.0',
        type = 'router',
        hostname = options.hostname,
        lat = options.lat,
        lon = options.lon,
        attributes = {
            script = 'luci-lib-libremap'
        }
    }

    -- let plugins insert data into doc
    for _, plugin in pairs(plugins) do
        plugin.insert(doc)
    end

    return doc
end


return libremap
