--[[

Copyright 2017 Roger Pueyo Centelles <roger.pueyo@guifi.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

]]--

local uci = (require 'uci').cursor()

function insert(doc, options)
    -- get values from qMp config
    local community_name = tostring(uci:get('qmp', 'node', 'community_name'))
    local mesh_name = tostring(uci:get('qmp', 'node', 'mesh_name'))
    local device_id = tostring(uci:get('qmp', 'node', 'device_id'))

    -- store in doc
    doc.community_name = community_name
    doc.mesh_name = mesh_name
    doc.device_id = device_id
end

return {
    insert = insert
}
