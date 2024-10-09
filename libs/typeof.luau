local customtypes = require("./customtypes")
local type = require("./type")
local weaktypes = require("./weaktypes")

return function(value)
	local mt = getmetatable(value :: any)
	local customtype = customtypes[mt] or weaktypes[mt]
	if customtype then
		return customtype
	end
	return type(value)
end :: typeof(typeof)
