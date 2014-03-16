--[[

Copyright 2014 Geneviève Bastien <gbastien@versatic.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

]]--

local libremap = require 'luci.libremap'
local util = require 'luci.libremap.util'
local utl = require 'luci.util'
local json = require 'luci.json'

sys = require 'luci.sys'

-- insert babel info into doc
function insert(doc)
    -- init fields in doc (if not yet present)
    doc.aliases = doc.aliases or {}
    doc.links = doc.links or {}
            
    --todo: make that cleaner
    --todo: get /var/log/babeld.log from babel configuration
    --todo: need better aliases: local is the mac and remote the neigbour's id in babel... that won't do to map links (or add the aliases like they do in olsr?)
    local output = utl.exec('LINESBEFORE=$(wc -l /var/log/babeld.log | cut -d\' \' -f1); /etc/init.d/babeld status; LINESAFTER=$(wc -l /var/log/babeld.log | cut -d\' \' -f1);tail -`expr $LINESAFTER - $LINESBEFORE - 1` /var/log/babeld.log')
    local links = utl.exec('echo \''..output..'\' | grep Neighbour | cut -d\' \' -f2')
    local myid = utl.exec('echo \''..output..'\' | grep \'My id\' | cut -d\' \' -f3')
    local myid2 = string.match(myid,"[%w+%p*]+")
    local jsonstring = json.encode(links)    
    for l in string.gmatch(links,"[%w+%p*]+") do
        doc.links[#doc.links+1] = { 
            type = 'babel',
            alias_remote = l,
            alias_local = myid2
        }
    end
end                                
                                                                                                                    
return {
    insert = insert
}
