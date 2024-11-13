local typeof = require("./globals").typeof

local gmatch = string.gmatch
local insert = table.insert

local function split(inputstr, sep): { string }
	sep = sep or "%s"
	local t = {}
	for field, s in gmatch(inputstr, "([^" .. sep .. "]*)(" .. sep .. "?)") do
		insert(t, field)
		if s == "" then
			return t
		end
	end
	return { inputstr }
end

pcall(function()
	local stringMt = (getmetatable :: any)("")
	stringMt.split = split
end)

return {
	split = split,
	byte = string.byte,
	char = string.char,
	find = string.find,
	format = string.format,
	gmatch = string.gmatch,
	gsub = string.gsub,
	len = string.len,
	lower = string.lower,
	match = string.match,
	pack = string.pack,
	packsize = string.packsize,
	rep = string.rep,
	reverse = string.reverse,
	sub = string.sub,
	unpack = string.unpack,
	upper = string.upper,
} :: typeof(string)
