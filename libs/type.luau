local nativetypes = require("./nativetypes")
local weaktypes = require("./weaktypes")

return function(value)
	local customtype = weaktypes[value]
	if customtype then
		return customtype
	end
	local mt = getmetatable(value :: any)
	customtype = nativetypes[mt]
	if customtype then
		return customtype
	end
	return type(value)
end :: typeof(typeof)
