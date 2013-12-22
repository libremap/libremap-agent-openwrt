--[[

Copyright 2013 André Gaul <gaul@web-yard.de>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

]]--

local libremap = {}

local util = require 'libremap.util'


--- Gather data for libremap about this router
function libremap.gather(options)
    options = util.defaults(options, {
        contact = true,
        hash_macs = true,
        plugins = 'all'
    })
end


return libremap
