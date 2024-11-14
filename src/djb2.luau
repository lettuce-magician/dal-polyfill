local byte = string.byte
local band = bit32.band

return function(str: string): number
	local hash = 5381

	for i = 1, #str do
		hash = hash * 33 + byte(str, i)
		hash = band(hash, 0xffffffff)
	end

	return hash
end
