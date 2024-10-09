local nativetypes = require("./nativetypes")

return function(value)
	local mt = getmetatable(value :: any)
	local customtype = nativetypes[mt]
	if customtype then
		return customtype
	end
	return type(value)
end :: typeof(typeof)
