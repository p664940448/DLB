#!/usr/bin/env lua
local cjson = require "cjson"
local ups = ngx.shared.dyn_ups_zone:get("myServers")

if ups ~=nil then
    local serverTable = {}
    local total = 0

    serverTable = cjson.decode(ups)
    for k,v in ipairs(serverTable) do
    	if v.state=="on" and v.health=="Y" then
	    	v.cweight = v.cweight + v.weight
	    	total = total + v.cweight
	    end
    end

    --取最大weight，选server，置cweight
    local selectServer=""
    local maxWeight = -100000
    local index = 0
    for k,v in ipairs(serverTable) do
    	if v.state=="on" and v.health=="Y" then
	        local map = v
	        if map.cweight > maxWeight then
	            maxWeight = map.cweight
	            selectServer = map.host
	            index = k
	        end
    	end
    end
    serverTable[index].cweight = serverTable[index].cweight - total

    local upss_string = cjson.encode(serverTable)
    ngx.shared.dyn_ups_zone:set("myServers",upss_string)

    return selectServer
end


ngx.log(ngx.INFO,"error")
return "myServers"
