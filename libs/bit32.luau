local isnumber = require("./isnumber")

local LN2 = math.log(2)
local log = math.log
local floor = math.floor
local band = bit32.band
local rshift = bit32.rshift
local lshift = bit32.lshift
local bnot = bit32.bnot
local bor = bit32.bor

local function arshift(x: number, disp: number): number
	if _G.DAL_runtime_type_checking then
		if not isnumber(x) then
			error(`invalid argument #1 to 'arshift' (number expected, got {typeof(x)})`)
		elseif not isnumber(disp) then
			error(`invalid argument #2 to 'arshift' (number expected, got {typeof(disp)})`)
		end
	end

	local z = rshift(x, disp)
	if x >= 0x80000000 then
		z = z + lshift(2 ^ disp - 1, 32 - disp)
	end
	return z
end

-- local function btest(x: number, y: number): boolean -- can be converted directly?
-- 	return bit32.band(x, y) ~= 0
-- end

local function extract(n: number, field: number, width: number): number
	if _G.DAL_runtime_type_checking then
		if not isnumber(n) then
			error(`invalid argument #1 to 'extract' (number expected, got {typeof(n)})`)
		elseif not isnumber(field) then
			error(`invalid argument #2 to 'extract' (number expected, got {typeof(field)})`)
		elseif not isnumber(width) then
			error(`invalid argument #3 to 'extract' (number expected, got {typeof(width)})`)
		end
	end

	width = width or 1
	return band(rshift(n, field), 2 ^ width - 1)
end

local function rrotate(x: number, disp: number): number
	if _G.DAL_runtime_type_checking then
		if not isnumber(x) then
			error(`invalid argument #1 to 'rrotate' (number expected, got {typeof(x)})`)
		elseif not isnumber(disp) then
			error(`invalid argument #2 to 'rrotate' (number expected, got {typeof(disp)})`)
		end
	end

	disp = disp % 32
	local low = band(x, 2 ^ disp - 1)
	return rshift(x, disp) + lshift(low, 32 - disp)
end

local function lrotate(x: number, disp: number): number
	if _G.DAL_runtime_type_checking then
		if not isnumber(x) then
			error(`invalid argument #1 to 'rrotate' (number expected, got {typeof(x)})`)
		elseif not isnumber(disp) then
			error(`invalid argument #2 to 'rrotate' (number expected, got {typeof(disp)})`)
		end
	end

	return rrotate(x, -disp)
end

local function replace(n: number, v: number, field: number, width: number): number
	if _G.DAL_runtime_type_checking then
		if not isnumber(n) then
			error(`invalid argument #1 to 'replace' (number expected, got {typeof(n)})`)
		elseif not isnumber(v) then
			error(`invalid argument #2 to 'replace' (number expected, got {typeof(v)})`)
		elseif not isnumber(field) then
			error(`invalid argument #3 to 'replace' (number expected, got {typeof(field)})`)
		elseif not isnumber(width) then
			error(`invalid argument #3 to 'replace' (number expected, got {typeof(width)})`)
		end
	end

	width = width or 1
	local mask1 = 2 ^ width - 1
	v = band(v, mask1) -- required by spec?
	local mask = bnot(lshift(mask1, field))
	return band(n, mask) + lshift(v, field)
end

local function countrz(x: number): number
	if _G.DAL_runtime_type_checking then
		if not isnumber(x) then
			error(`invalid argument #1 to 'countrz' (number expected, got {typeof(x)})`)
		end
	end

	local as32bit = rshift(x, 0)
	if as32bit == 0 then
		return 32
	end

	local count = 0
	while band(as32bit, 1) == 0 do
		as32bit = rshift(as32bit, 1)
		count += 1
	end
	return count
end

local function countlz(x: number): number
	if _G.DAL_runtime_type_checking then
		if not isnumber(x) then
			error(`invalid argument #1 to 'countlz' (number expected, got {typeof(x)})`)
		end
	end

	local as32bit = rshift(x, 0)
	if as32bit == 0 then
		return 32
	end
	return 31 - floor(log(as32bit) / LN2)
end

local function byteswap(n: number): number
	if _G.DAL_runtime_type_checking then
		if not isnumber(n) then
			error(`invalid argument #1 to 'byteswap' (number expected, got {typeof(n)})`)
		end
	end

	return bor(bor(bor(lshift(n, 24), band(lshift(n, 8), 0xff0000)), band(rshift(n, 8), 0xff00)), rshift(n, 24))
end

return bit32
	or {
		arshift = arshift,
		extract = extract,
		lrotate = lrotate,
		replace = replace,
		countrz = countrz,
		countlz = countlz,
		byteswap = byteswap,
	} -- for lua54 or something
