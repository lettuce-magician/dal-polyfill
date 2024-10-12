local customtypes = require("./customtypes")
local type = require("./type")

return function(value)
	local mt = getmetatable(value :: any)
	local customtype = customtypes[mt]
	if customtype then
		return customtype
	end
	return type(value)
end :: typeof(typeof)
