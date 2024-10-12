--[=[
	Metatable related injectable functions for emulating generalized iteration.
]=]
local iter = {}
local getmetatable = require("./getmetatable")

local lockedIteratableTables = setmetatable({}, { __mode = "k" })

iter.__DAL_getmetatable = (
	function(tbl)
		local lockedTbl = lockedIteratableTables[tbl]
		if lockedTbl then
			return {
				__iter = lockedTbl,
			}
		end
		return getmetatable(tbl)
	end :: any
) :: typeof(getmetatable)

iter.setmetatable = (
	function(tbl: {}, mt: { [any]: any })
		if mt.__metatable then
			local iterMethod = mt.__iter
			if iterMethod then
				lockedIteratableTables[tbl] = iterMethod
			end
		end
		return setmetatable(tbl, mt)
	end :: any
) :: typeof(setmetatable)

return iter
