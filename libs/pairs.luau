local djb2 = require("./djb2")
local frozentables = require("./frozentables")

return {
	withHash = (function(t)
		local frozen = frozentables[t]
		if frozen then
			t = frozen[2]
		end

		local keys = {}
		local hashmap = {}
		for key in pairs(t) do
			local hash
			if type(key) == "number" then
				hash = key
			else
				hash = djb2(tostring(key))
			end
			table.insert(keys, hash)
			hashmap[hash] = key
		end

		table.sort(keys, function(a, b)
			return a < b
		end)

		local i = 0
		return function(): any
			i = i + 1
			local hashkey = keys[i]
			if hashkey then
				local key = hashmap[hashkey]
				if key then
					return key, t[key]
				end
			end
			return
		end
	end :: any) :: typeof(pairs),
	withoutHash = (function(t)
		local frozen = frozentables[t]
		if frozen then
			t = frozen[2]
		end
		return pairs(t)
	end :: any) :: typeof(pairs)
}
