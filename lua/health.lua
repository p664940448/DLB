#!/usr/bin/env lua

local log = ngx.log
local ERR = ngx.ERR
local WARN = ngx.WARN
local DEBUG = ngx.DEBUG
local new_timer = ngx.timer.at
local wait = ngx.thread.wait
local stream_sock = ngx.socket.tcp
local cjson = require "cjson"
local pcall = pcall

local _M = {
	_VERSION = "1.0"
}

--参数
--interval 检查时间间隔，单位秒
--fall 连续失败n次后设置server为down
--rise 连续成功n次后设置server为up
--timeout tcp超时时间 毫秒
local options = {
	interval = 5,
	fall = 2,
	rise = 1,
	timeout = 3000
}

local function errlog(...)
    log(ERR, "healthcheck: ", ...)
end

--切割字符串
local function split(s,delim)
    if type(delim) ~= "string" or string.len(delim) <= 0 then
        return
    end

    local start = 1
    local t = {}
    while true do
        local pos = string.find(s,delim,start,true)
        if not pos then
            break
        end
        table.insert(t,string.sub(s,start,pos - 1))
        start = pos + string.len(delim)
    end
    table.insert( t, string.sub(s,start))
    return t
end

--设置server健康状态
local function setServerState(host,health)
	local upss = ngx.shared.dyn_ups_zone:get("myServers")
	local serverTable = cjson.decode(upss)
	for k,v in pairs(serverTable) do
		if v.host == host then
			v.health=health
		end
	end
	ngx.shared.dyn_ups_zone:set("myServers",cjson.encode(serverTable))
end
--监测单个server
local function checkServer(host,options)
	local ok
	local sock, err = stream_sock()
    if not sock then
        errlog("failed to create stream socket: ", err)
        return
    end

	sock:settimeout(options.timeout)

	local hostTable = split(host,":")
	if #hostTable==1 then
		table.insert(hostTable,80)
	end

	ok, err = sock:connect(hostTable[1], hostTable[2])
	if not ok then
		setServerState(host,"N")
	else
		setServerState(host,"Y")		
	end
	sock:close()

end

--轮流监测多个server
local function checkServers()
	local upss = ngx.shared.dyn_ups_zone:get("myServers")
	local serverTable = cjson.decode(upss)
	if serverTable~=nil then
		for k,v in pairs(serverTable) do
			checkServer(v.host,options)
		end
	end
	return true,""
end

local check
check = function ()
    local ok, err = pcall(checkServers)
    if not ok then
        errlog("failed to run healthcheck cycle: ", err)
    end

    local ok, err = new_timer(options.interval, check)
    if not ok then
        if err ~= "process exiting" then
            errlog("failed to create timer: ", err)
        end
        return
    end
end


function _M.init()
	errlog("==== enter init====")
	local ok, err = new_timer(0, check)
    if not ok then
        return nil, "failed to create timer: " .. err
    end
    return true,""
end

return _M


