--[[

Copyright 2013 André Gaul <gaul@web-yard.de>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

]]--

local util = {}


--- Sets defaults in table (copies options)
function util.defaults(options, default)
    local ret = {}
    for k, v in pairs(options or {}) do
        ret[k] = v
    end
    for k, v in pairs(default) do
        if ret[k]==nil then
            ret[k] = v
        end
    end
    return ret
end


--[[
Exceptions à la try/catch, see http://www.lua.org/wshop06/Belmonte.pdf

usage:

local try = require 'util.try'
try(function()
    -- Try block
    --
end, function(e)
    -- Except block. E.g.:
    --  Use e for conditional catch
    --  Re-raise with error(e)
end)
]]--
function util.try(f, catch_f)
    local status, exception = pcall(f)
    if not status then
        catch_f(exception)
    end
end

return util
