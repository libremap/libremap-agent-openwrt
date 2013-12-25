--[[

Copyright 2013 André Gaul <gaul@web-yard.de>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

]]--

function insert(doc, options)
    doc.latitude = options.latitude
    doc.longitude = options.longitude
    doc.elev = options.elev
end

return {
    insert = insert
}
