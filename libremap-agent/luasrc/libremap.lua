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
local nixio = require 'nixio'

local util = require 'luci.libremap.util'


--- Gather data for libremap about this router
function libremap.gather(plugins, id, rev, community, old_doc)
    local plugins = plugins or {}

    -- check if revisions match
    if old_doc~=nil then
        if rev~=old_doc._rev then
            nixio.syslog('warning', 'revision mismatch ('..(rev or 'nil')..' != '..old_doc._rev..')')
        end
    end

    -- load plugins from luci.libremap.plugins.*
--    local plugins = {}
    local plugin_names = {}
    local i = 1
    for name, options in pairs(plugins) do
        util.try(function ()
            plugins[name] = {
                module = require('luci.libremap.plugins.'..name),
                options = options
            }
            plugin_names[i] = name
            i=i+1
        end, function(e)
            nixio.syslog('warning', 'unable to load plugin "'..name..'"; '..e)
        end)
    end

    -- create libremap table
    local version = sys.exec('opkg status libremap-agent | grep Version')
    version = version:match('^Version: (.*)\n')
    local doc = {
        _id = id,
        api_rev = '1.0',
        type = 'router',
        hostname = sys.hostname(),
        community = community,
        attributes = {
            submitter = {
                name = 'libremap-agent-openwrt',
                version = version,
                url = 'https://github.com/libremap/libremap-agent-openwrt',
                plugins = plugin_names
            }
        }
    }

    if old_doc~=nil then
        doc._id = old_doc._id
        doc._rev = old_doc._rev
        doc.ctime = old_doc.ctime
    end

    -- let plugins insert data into doc
    for name, plugin in pairs(plugins) do
        util.try(function()
            plugin.module.insert(doc, plugin.options, old_doc)
        end, function(e)
            nixio.syslog('warning', 'unable to execute plugin "'..name..'"; '..e)
        end)
    end

    return doc
end

-- fixed http client function (based on luci.httpclient)
local ltn12 = require "luci.ltn12"

--- HTTP request
-- returns:
--  response - the response body
--  code     - HTTP status code
--  headers  - response headers
function libremap.http(uri, options)
    local code, response, buffer, sock = httpc.request_raw(uri, options)
    if not code then
        return response, -1, nil
    end

    local source
    if response.headers["Transfer-Encoding"] == "chunked" then
        source = httpc.chunksource(sock, buffer)
    else
        source = ltn12.source.cat(ltn12.source.string(buffer), sock:blocksource())
    end

    local output = {}
    ltn12.pump.all(source, (ltn12.sink.table(output)))
    return table.concat(output), code, response.headers
end

--- Fetch a document from the database
-- Returns nil if document is not available
function libremap.fetch(api_url, id)
    if not id then
        return nil
    end

    -- id given -> check if doc is present in db
    local response, code, headers = libremap.http(api_url..'/router/'..id)
    if code<200 or code>=300 then
        -- 404 -> everything smooth, create new doc
        if code~=404 then
            -- other error
            error('could not determine if id '..id..' is already available under API at '..api_url..' (code '..(code or 'nil')..')')
        end
    else
        -- doc already present
        return json.decode(response)
    end
    return nil
end

--- Fetch a document from the database by hostname and community
-- Returns nil if document is not available
function libremap.fetch_by_name(api_url, community)
    if not community then
        return nil
    end

    local doc = { include_docs=true, keys={{ sys.hostname(), community }} }
    local options = { method = 'POST' }
    options.body = json.encode(doc)

    -- community given -> check if doc is present in db
    local response, code, headers = libremap.http(api_url..'/routers_by_name_community/', options)

    if code<200 or code>=300 then
        -- 404 -> everything smooth, create new doc
        if code~=404 then
            -- other error
            error('could not determine if router is already present under API at '..api_url..' (code '..(code or 'nil')..')')
        end
    else
        local decoded = json.decode(response)
        -- doc exists for this hostname + community
        if # decoded.rows == 1 then
            local old_doc = decoded.rows[1].value
            return old_doc
        else
            nixio.syslog('warning', 'more than one record matches the criteria. fetch by name aborted.')
        end
    end
    return nil
end

--- Submit a document to the database
-- returns the id (new uuid from api_url if no id was given)
function libremap.submit(api_url, doc)
    local options = {
        headers = {
            ["Content-Type"] = "application/json"
        }
    }
    local url = api_url..'/router/'
    if doc._id==nil then
        -- create new doc
        options.method = 'POST'
    else
        -- update doc (or create if id was given)
        options.method = 'PUT'
        url = url..doc._id
    end
    options.body = json.encode(doc)

    -- send the create/update request
    local response, code, headers = libremap.http(url, options)
    if code<200 or code>=300 then
        error('error creating/updating router document at URL '..url..'; '..response)
    end

    -- get new revision
    local rev = headers['X-Couch-Update-NewRev']

    return doc._id or json.decode(response).id, rev
end


return libremap
