local weaktypes = require("./weaktypes")
local userdata = require("./userdata")
local table = require("./table")

return (function(mt: boolean)
	local newud = {}
	if mt then
		local newMt = table.clone(userdata)
		setmetatable(newud, newMt)
		weaktypes[newMt] = "userdata"
	else
		setmetatable(newud, userdata)
	end
	return newud
end :: any) :: typeof(newproxy)
