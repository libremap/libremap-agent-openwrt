--[[

Copyright 2013 Patrick Grimm <patrick@lunatiki.de>
Copyright 2013 André Gaul <gaul@web-yard.de>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

]]--

local libremap = {}

local fs = require 'luci.fs'
local httpc = require 'luci.httpclient'
local json = require 'luci.json'
local sys = require 'luci.sys'
local string = require 'string'

local util = require 'luci.libremap.util'


--- Gather data for libremap about this router
function libremap.gather(options)
    options = util.defaults(options, {
        plugins = {},
        hostname = sys.hostname(),
    })

    -- load plugins from luci.libremap.plugins.*
    local plugins = {}
    for name, options in pairs(options.plugins) do
        util.try(function ()
            plugins[name] = {
                module = require('luci.libremap.plugins.'..name),
                options = options
            }
        end, function(e)
            print('warning: unable to load plugin "'..name..'"; '..e)
        end)
    end

    -- create libremap table
    local doc = {
        api_rev = '1.0',
        type = 'router',
        hostname = options.hostname,
        attributes = {
            script = 'luci-lib-libremap'
        }
    }

    -- let plugins insert data into doc
    for name, plugin in pairs(plugins) do
        util.try(function()
            plugin.module.insert(doc, plugin.options)
        end, function(e)
            print('warning: unable to execute plugin "'..name..'"; '..e)
        end)
    end

    return doc
end

-- fixed versions from luci.httpclient
local ltn12 = require "luci.ltn12"
function request_to_buffer(uri, options)
    local source, code, msg, headers = request_to_source(uri, options)
    local output = {}

    if not source then
        return nil, code, msg, headers
    end

    source, code = ltn12.pump.all(source, (ltn12.sink.table(output)))

    if not source then
        return nil, code, nil, headers
    end

    return table.concat(output), code, nil, headers
end
function request_to_source(uri, options)
    local status, response, buffer, sock = httpc.request_raw(uri, options)
    if not status then
        return status, response, buffer
    elseif status < 200 or status >= 300 then
        return nil, status, buffer
    end

    if response.headers["Transfer-Encoding"] == "chunked" then
        return httpc.chunksource(sock, buffer), nil, nil, response.headers
    else
        return ltn12.source.cat(ltn12.source.string(buffer), sock:blocksource()), nil, nil, response.headers
    end
end


--- Submit a document to the database
-- returns the id (new uuid from api_url if no id was given)
function libremap.submit(api_url, id, rev, doc)
    local olddoc = nil
    if id~=nil then
        -- id given -> check if doc is present in db
        local response, code, msg = httpc.request_to_buffer(api_url..'/router/'..id)
        if response==nil then
            -- 404 -> everything smooth, create new doc
            if code~=404 then
                -- other error
                error('could not determine if id '..id..' is already available under API at '..api_url..' (code '..(code or 'nil')..')')
            end
        else
            -- doc already present
            olddoc = json.decode(response)
        end
    end

    local options = {
        headers = {
            ["Content-Type"] = "application/json"
        }
    }
    local url = api_url..'/router/'
    if id==nil then
        -- create new doc
        options.method = 'POST'
    else
        -- update doc (or create if id was given)
        options.method = 'PUT'
        url = url..id
        doc._id = id
        if olddoc~=nil then
            if rev~=olddoc._rev then
                print('warning: revision mismatch ('..rev..' != '..olddoc._rev..')')
            end
            -- update
            doc._rev = olddoc._rev
            doc.ctime = olddoc.ctime
        end
    end
    options.body = json.encode(doc)

    -- send the create/update request
    local response, code, msg, headers = request_to_buffer(url, options)
    if response==nil then
        error('error creating/updating router document at URL '..url..'; '..msg)
    end

    -- get new revision
    local rev = headers['X-Couch-Update-NewRev']

    return id or json.decode(response).id, rev
end


return libremap
