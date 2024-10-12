local weaktypes = require("./weaktypes")
local userdata = require("./userdata")
local table = require("./table")
local nativetypes = require("./nativetypes")
local proxies = require("./proxies")
local privatekey = require("./privatekey")

local clone = table.clone
nativetypes[userdata] = "userdata"

local Proxy = {}

function Proxy.__newindex(self, k, v)
	self[privatekey][k] = v
	rawset(self, k, v)
end

return (
	function(mt: boolean)
		local newud = {}
		if mt then
			local proxyMt = clone(userdata)
			setmetatable(newud, proxyMt)
			proxies[newud] = setmetatable({
				[privatekey] = proxyMt
			}, Proxy)
			weaktypes[newud] = "userdata"
		else
			setmetatable(newud, userdata)
		end
		return newud
	end :: any
) :: typeof(newproxy)
