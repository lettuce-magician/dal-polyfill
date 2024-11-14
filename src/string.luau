local typeof = require("./globals").typeof
local isstring = require("./isstring")

local gmatch = string.gmatch
local insert = table.insert

local function split(inputstr: string, sep: string): { string }
	if _G.DAL_runtime_type_checking then
		if not isstring(inputstr) then
			error(`invalid argument #1 to 'split' (string expected, got {typeof(inputstr)})`)
		elseif not isstring(sep) then
			error(`invalid argument #2 to 'split' (string expected, got {typeof(sep)})`)
		end
	end
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
