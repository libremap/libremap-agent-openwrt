--[[

Copyright 2013 Patrick Grimm <patrick@lunatiki.de>
Copyright 2013 André Gaul <gaul@web-yard.de>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

]]--

sys  = require 'luci.sys'
util = require 'luci.util'

return {
    insert = function(doc, options)
        local sysinfo = util.ubus("system", "info") or { }
        local sysboard = util.ubus("system", "board") or { }

        local system = { }
        system["name"] = sysinfo["hostname"]
        system["model"] = sysboard["system"]
        system["memtotal"] = sysinfo["memory"]["total"]

        doc.attributes = doc.attributes or {}
        doc.attributes.system = system
    end
}
