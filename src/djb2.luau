local byte = string.byte

return function(str: string): number
	local hash = 5381

	for i = 1, #str do
		hash = hash * 33 + byte(str, i)
		hash = bit32.band(hash, 0xffffffff)
	end

	return hash
end
