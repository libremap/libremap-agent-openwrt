--! LibreMap Babeld Plugin
--! Copyright (C) 2018  Gioacchino Mazzurco <gio@altermundi.net>
--!
--! This program is free software: you can redistribute it and/or modify
--! it under the terms of the GNU Affero General Public License as
--! published by the Free Software Foundation, either version 3 of the
--! License, or (at your option) any later version.
--!
--! This program is distributed in the hope that it will be useful,
--! but WITHOUT ANY WARRANTY; without even the implied warranty of
--! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--! GNU Affero General Public License for more details.
--!
--! You should have received a copy of the GNU Affero General Public License
--! along with this program.  If not, see <http://www.gnu.org/licenses/>.


local libuci = require("uci")
local nixio = require("nixio")

local function split(string, sep)
	local ret = {}
	for token in string.gmatch(string, "[^"..sep.."]+") do
		table.insert(ret, token)
	end
	return ret
end

local function insert(doc)
	doc.aliases = doc.aliases or {}
	doc.links = doc.links or {}
	doc.attributes = doc.attributes or {}

	function mLog(mType, mMessage)
		nixio.syslog(mType, mMessage)
		doc.debug = doc.debug or {}
		table.insert(doc.debug, mType.." "..mMessage)
	end

	local bblMonitorPort = -1
	function savePort(s)
		if type(s.local_port) ~= "nil" then
			bblMonitorPort = tonumber(s.local_port)
		end
	end
	local uci = libuci:cursor()
	uci:foreach("babeld", "general", savePort)
	uci = nil

	if not (bblMonitorPort >= 0 and bblMonitorPort <= 65535) then
		mLog("err", "Could not determine Babeld monitoring local-port")
		return
	end

	local ncStdOut = io.popen("echo dump | nc ::1 " .. bblMonitorPort)

	local exptectedBblCtrlProto = "BABEL 1.0"
	local bblCtrlProto = ncStdOut:read()
	if bblCtrlProto ~= exptectedBblCtrlProto then
		mLog( "err",
		      "Babeld control protocol mismatch expected: " ..
		      exptectedBblCtrlProto .. " got: " .. bblCtrlProto )
		return
	end

	local bblVersion = ncStdOut:read()
	if not bblVersion then
		mLog("err", "could not determine babeld version")
		return
	end
	doc.attributes.babel_version = split(bblVersion, " ")[2]

	ncStdOut:read() -- discard hostname line

	local mId = split(ncStdOut:read(), " ")
	if mId[1] ~= "my-id" or not mId[2] then
		mLog("err", "Cannot parse Babeld router id")
		return
	end
	table.insert( doc.aliases, {type="babeld", alias=mId[2]} )

	if(ncStdOut:read() ~= "ok") then
		mLog("err", "Cannot parse Babeld 'ok' line")
	end

	local ifaceIp6Map = {}
	local mLine = ncStdOut:read()
	while mLine do
		local mTable = split(mLine, " ")

		if mTable[1] == "add" then
			if mTable[2] == "interface" and mTable[5] == "true" then
				table.insert( doc.aliases, { type="babel", alias=mTable[7] } )
				table.insert( doc.aliases, { type="babel", alias=mTable[9] } )
				ifaceIp6Map[mTable[3]] = mTable[7]
			else
				if mTable[2] == "neighbour" then
					local mLink = {
						type = "babel",
						alias_local = ifaceIp6Map[mTable[7]],
						alias_remote = mTable[5],
						quality = 255/mTable[17],
						attributes = {
							l2_interface = mTable[7],
							reach = mTable[9],
							ureach = mTable[11],
							rxcost = mTable[13],
							txcost = mTable[15],
							cost = mTable[17]
						}
					}
					table.insert(doc.links, mLink)
				end
			end
		else
			if mTable[1] == "ok" then return end
		end

		mLine = ncStdOut:read()
	end
end

return { insert = insert }
