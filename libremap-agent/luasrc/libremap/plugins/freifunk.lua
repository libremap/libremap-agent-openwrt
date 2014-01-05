--[[

Copyright 2013 André Gaul <gaul@web-yard.de>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

]]--

local uci = (require 'uci').cursor()

function insert(doc, options, old_doc)
    -- get values from system config
	local lat = tonumber(uci:get_first('system', 'system', 'latitude'))
	local lon = tonumber(uci:get_first('system', 'system', 'longitude'))
	local elev = tonumber(uci:get_first('system', 'system', 'elevation'))
    if old_doc then
        if lat == nil or lon == nil then
            lat = old_doc.lat
            lon = old_doc.lon
        end
        if elev == nil then
            elev = old_doc.elev
        end
    end

    -- store in doc
    doc.lat = lat
    doc.lon = lon
    doc.elev = elev
end

return {
    insert = insert
}
