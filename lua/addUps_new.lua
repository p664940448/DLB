#!/usr/bin/env lua

local cjson = require "cjson"
local ps = require("password")
if not ps.checkLogin2() then
	return
end

ngx.req.read_body()
local serverName = ngx.req.get_post_args()["serverName"]
local host = ngx.req.get_post_args()["host"]
local weight = ngx.req.get_post_args()["weight"]
local op = ngx.req.get_post_args()["op"]
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

if weight==nil then
	resultMap["state"]="fail"
	resultMap["message"]="缺少参数weight"
	ngx.say(cjson.encode(resultMap))
	return
end

if op==nil then
	resultMap["state"]="fail"
	resultMap["message"]="缺少参数op"
	ngx.say(cjson.encode(resultMap))
	return
end

local dynupszone = ngx.shared.dyn_ups_zone;
local jsonStr = dynupszone:get("myServers");
local serverTable1 = cjson.decode(jsonStr)

if serverTable1~=nil then
	if op=="add" then
		for key,value in pairs(serverTable1) do
			if host== value.host or serverName == value.serverName then
				resultMap["state"]="fail"
				resultMap["message"]="host或者serverName已存在"
				ngx.say(cjson.encode(resultMap))
				return
			end
		end
	end	
end


--存入dict
local upss = dynupszone:get("myServers");
local serverTable={}
if op=="add" then
	serverTable = cjson.decode(upss)
	local map = {}
	map.host = host
	map.weight = weight
	map.serverName = serverName
	map.state="on"
	map.health="Y"
	table.insert(serverTable,map)
	--cweight清0，重新分配权重
	for k,v in pairs(serverTable) do
		v.cweight=0
	end
else
	serverTable = cjson.decode(upss)
	for k,v in pairs(serverTable) do
		v.cweight=0
		if v.host == host then
			v.serverName = serverName
			v.weight = weight
		end
	end
end

dynupszone:set("myServers",cjson.encode(serverTable))
--ngx.log(ngx.INFO,"===upss==",cjson.encode(serverTable))
--生成文件保存
local file = io.open("conf/proxy_new.json","w+")
local str = cjson.encode(serverTable)
file:write( str )
file:close()

--返回
resultMap["state"]="success"
resultMap["message"]=""
ngx.say(cjson.encode(resultMap))




