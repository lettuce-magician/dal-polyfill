local nativetypes = require("./nativetypes")
local frozentables = require("./frozentables")
local proxies = require("./proxies")

return (
	function(value)
		local frozen = frozentables[value]
		if frozen then
			return frozen[1]
		end
		local mt = proxies[value] or getmetatable(value)
		if nativetypes[mt] then
			return nil
		end
		return mt
	end :: any
) :: typeof(getmetatable)
