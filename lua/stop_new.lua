#!/usr/bin/env lua

local cjson = require "cjson"
local ps = require("password")
if not ps.checkLogin2() then
	return
end

local serverName = ngx.req.get_uri_args()["serverName"]
local host = ngx.req.get_uri_args()["host"]
local weight = ngx.req.get_uri_args()["weight"]
local state = ngx.req.get_uri_args()["state"]
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

if state==nil then
	resultMap["state"]="fail"
	resultMap["message"]="缺少参数state"
	ngx.say(cjson.encode(resultMap))
	return
end

local upss = ngx.shared.dyn_ups_zone:get("myServers")
local serverTable = cjson.decode(upss)

if state=="on" then
	for k,v in ipairs(serverTable) do
		v.cweight = 0
		if host == v.host then
			v.state = "on"
		end
	end
else
	for k,v in ipairs(serverTable) do
		v.cweight = 0
		if host == v.host then
			v.state = "off"
		end
	end
end 

local upss_string = cjson.encode(serverTable)
ngx.shared.dyn_ups_zone:set("myServers",upss_string)
--保存文件
local file = io.open("conf/proxy_new.json","w+")
file:write( cjson.encode(serverTable) )
file:close()

resultMap["state"]="success"
resultMap["message"]=""
ngx.say(cjson.encode(resultMap))

