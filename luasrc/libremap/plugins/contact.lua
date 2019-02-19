--[[

Copyright 2013 Patrick Grimm <patrick@lunatiki.de>
Copyright 2013 André Gaul <gaul@web-yard.de>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

]]--

return {
    insert = function(doc, options)
        local contact = {
            name = options.name,
            email = options.email
        }
        doc.attributes = doc.attributes or {}
        doc.attributes.contact = contact
    end
}
