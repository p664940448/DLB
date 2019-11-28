#!/usr/bin/env lua

local cjson = require "cjson"
local ps = require("password")
if not ps.checkLogin2() then
	return
end

local serverName = ngx.req.get_uri_args()["serverName"]
local host = ngx.req.get_uri_args()["host"]
local resultMap = {}

if serverName==nil then
	resultMap["state"]="fail"
	resultMap["message"]="缺少参数serverName"
	ngx.say(cjson.encode(resultMap))
	return
end

if host==nil then
	resultMap["state"]="fail"
	resultMap["message"]="缺少参数host"
	ngx.say(cjson.encode(resultMap))
	return
end

local dynupszone = ngx.shared.dyn_ups_zone;
local upss = dynupszone:get("myServers")

--解析upss,去掉host
local serverTable = cjson.decode(upss)
for i=#serverTable,1,-1 do
	serverTable[i].cweight = 0
	serverTable[i].health = true
	if host == serverTable[i].host then
		table.remove(serverTable,i)
	end
end

--把table转为字串，保存
local upss_string = cjson.encode(serverTable)
ngx.shared.dyn_ups_zone:set("myServers",upss_string)

--保存文件
local file = io.open("conf/proxy_new.json","w+")
file:write( cjson.encode(serverTable) )
file:close()

resultMap["state"]="success"
resultMap["message"]=""
ngx.say(cjson.encode(resultMap))

