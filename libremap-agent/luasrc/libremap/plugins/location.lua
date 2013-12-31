--[[

Copyright 2013 André Gaul <gaul@web-yard.de>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

]]--

function insert(doc, options, old_doc)
    local lat = tonumber(options.latitude)
    local lon = tonumber(options.longitude)
    local elev = tonumber(options.elev)
    if old_doc then
        if lat == nil or lon == nil then
            lat = old_doc.lat
            lon = old_doc.lon
        end
        if elev == nil then
            elev = old_doc.elev
        end
    end
    doc.lat = lat
    doc.lon = lon
    doc.elev = elev
end

return {
    insert = insert
}
