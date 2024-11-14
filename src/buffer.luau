local buffer = {}

local privatekey = require("./privatekey")
local table = require("./table")
local math = require("./math")
local string = require("./string")
local nativetypes = require("./nativetypes")
local typeof = require("./globals").typeof
local isnumber = require("./isnumber")
local isstring = require("./isstring")

local band = bit32.band
local rshift = bit32.rshift
local bor = bit32.bor
local lshift = bit32.lshift
local concat = table.concat
local btest = bit32.btest
local abs = math.abs
local frexp = math.frexp
local floor = math.floor
local ldexp = math.ldexp
local huge = math.huge
local byte = string.byte

type buffer_polyfill = {
	[typeof(privatekey)]: { number }
}

local chars = table.create(256)
do
	for i = 0, 255 do
		chars[i + 1] = string.char(i)
	end
end

function buffer.create(size: number): buffer_polyfill
	if _G.DAL_runtime_type_checking then
		if not isnumber(size) then
			error(`invalid argument #1 to 'create' (number expected, got {typeof(size)})`)
		end
	end
	local data = table.create(size, 0)
	return {
		[privatekey] = data,
	}
end

function buffer.len(b: buffer_polyfill)
	return #b[privatekey]
end

-- function buffer.copy(target, targetOffset, source, sourceOffset, count)
-- 	local targetData = target[privatekey]
-- 	local sourceData = source[privatekey]
--     sourceOffset = sourceOffset or 0
--     count = count or #sourceData - sourceOffset

--     if target == source then
--         local temp = {}
--         for i = sourceOffset + 1, sourceOffset + count do
--             insert(temp, sourceData[i])
--         end

--         for i = 1, count do
--             targetData[targetOffset + i] = temp[i]
--         end
--     else
--         for i = 1, count do
--             targetData[targetOffset + i] = sourceData[sourceOffset + i]
--         end
--     end
-- end

function buffer.fill(b: buffer_polyfill, offset: number, value: number, count: number)
	if _G.DAL_runtime_type_checking then
		if not isnumber(offset) then
			error(`invalid argument #1 to 'fill' (number expected, got {typeof(offset)})`)
		elseif not isnumber(value) then
			error(`invalid argument #2 to 'fill' (number expected, got {typeof(value)})`)
		elseif not isnumber(count) then
			error(`invalid argument #3 to 'fill' (number expected, got {typeof(count)})`)
		end
	end
	local data = b[privatekey]
	count = count or (#data - offset + 1)
	value = band(value, 0xFF)

	for i = offset + 1, offset + count do
		data[i] = value
	end
end

-- unsigned integers

function buffer.writeu8(b: buffer_polyfill, offset: number, value: number)
	if _G.DAL_runtime_type_checking then
		if not isnumber(offset) then
			error(`invalid argument #1 to 'writeu8' (number expected, got {typeof(offset)})`)
		elseif not isnumber(value) then
			error(`invalid argument #2 to 'writeu8' (number expected, got {typeof(value)})`)
		end
	end
	b[privatekey][offset + 1] = band(value, 0xFF)
end

function buffer.writeu16(b: buffer_polyfill, offset: number, value: number)
	if _G.DAL_runtime_type_checking then
		if not isnumber(offset) then
			error(`invalid argument #1 to 'writeu16' (number expected, got {typeof(offset)})`)
		elseif not isnumber(value) then
			error(`invalid argument #2 to 'writeu16' (number expected, got {typeof(value)})`)
		end
	end
	local data = b[privatekey]
	data[offset + 1] = band(value, 0xFF)
	data[offset + 2] = band(rshift(value, 8), 0xFF)
end

function buffer.writeu32(b: buffer_polyfill, offset: number, value: number)
	if _G.DAL_runtime_type_checking then
		if not isnumber(offset) then
			error(`invalid argument #1 to 'writeu32' (number expected, got {typeof(offset)})`)
		elseif not isnumber(value) then
			error(`invalid argument #2 to 'writeu32' (number expected, got {typeof(value)})`)
		end
	end
	local data = b[privatekey]
	data[offset + 1] = band(value, 0xFF)
	data[offset + 2] = band(rshift(value, 8), 0xFF)
	data[offset + 3] = band(rshift(value, 16), 0xFF)
	data[offset + 4] = band(rshift(value, 24), 0xFF)
end

function buffer.readu8(b: buffer_polyfill, offset: number)
	if _G.DAL_runtime_type_checking then
		if not isnumber(offset) then
			error(`invalid argument #1 to 'readu8' (number expected, got {typeof(offset)})`)
		end
	end
	return b[privatekey][offset + 1]
end

function buffer.readu16(b: buffer_polyfill, offset: number)
	if _G.DAL_runtime_type_checking then
		if not isnumber(offset) then
			error(`invalid argument #1 to 'readu16' (number expected, got {typeof(offset)})`)
		end
	end
	local data = b[privatekey]
	return bor(data[offset + 1], lshift(data[offset + 2], 8))
end

function buffer.readu32(b: buffer_polyfill, offset: number)
	if _G.DAL_runtime_type_checking then
		if not isnumber(offset) then
			error(`invalid argument #1 to 'readu32' (number expected, got {typeof(offset)})`)
		end
	end
	local data = b[privatekey]
	return bor(
		bor(bor(data[offset + 1], lshift(data[offset + 2], 8)), lshift(data[offset + 3], 16)),
		lshift(data[offset + 4], 24)
	)
end

-- signed integers

function buffer.writei8(b: buffer_polyfill, offset: number, value: number)
	if _G.DAL_runtime_type_checking then
		if not isnumber(offset) then
			error(`invalid argument #1 to 'writei8' (number expected, got {typeof(offset)})`)
		elseif not isnumber(value) then
			error(`invalid argument #2 to 'writei8' (number expected, got {typeof(value)})`)
		end
	end
	if value < 0 then
		value = (128 + value) + 128
	end

	b[privatekey][offset + 1] = band(value, 0xFF)
end

function buffer.writei16(b: buffer_polyfill, offset: number, value: number)
	if _G.DAL_runtime_type_checking then
		if not isnumber(offset) then
			error(`invalid argument #1 to 'writei16' (number expected, got {typeof(offset)})`)
		elseif not isnumber(value) then
			error(`invalid argument #2 to 'writei16' (number expected, got {typeof(value)})`)
		end
	end
	if value < 0 then
		value = (32768 + value) + 32768
	end

	local data = b[privatekey]
	data[offset + 1] = band(value, 0xFF)
	data[offset + 2] = band(rshift(value, 8), 0xFF)
end

function buffer.writei32(b: buffer_polyfill, offset: number, value: number)
	if _G.DAL_runtime_type_checking then
		if not isnumber(offset) then
			error(`invalid argument #1 to 'writei32' (number expected, got {typeof(offset)})`)
		elseif not isnumber(value) then
			error(`invalid argument #2 to 'writei32' (number expected, got {typeof(value)})`)
		end
	end
	if value < 0 then
		value = (2147483648 + value) + 2147483648
	end

	local data = b[privatekey]
	data[offset + 1] = band(value, 0xFF)
	data[offset + 2] = band(rshift(value, 8), 0xFF)
	data[offset + 3] = band(rshift(value, 16), 0xFF)
	data[offset + 4] = band(rshift(value, 24), 0xFF)
end

function buffer.readi8(b: buffer_polyfill, offset: number)
	if _G.DAL_runtime_type_checking then
		if not isnumber(offset) then
			error(`invalid argument #1 to 'readi8' (number expected, got {typeof(offset)})`)
		end
	end
	local value = b[privatekey][offset + 1]
	local sign = btest(value, 128)
	value = band(value, 127)

	if sign then
		return value - 128
	else
		return value
	end
end

function buffer.readi16(b: buffer_polyfill, offset: number)
	if _G.DAL_runtime_type_checking then
		if not isnumber(offset) then
			error(`invalid argument #1 to 'readi16' (number expected, got {typeof(offset)})`)
		end
	end
	local data = b[privatekey]
	local value = bor(data[offset + 1], lshift(data[offset + 2], 8))
	local sign = btest(value, 32768)
	value = band(value, 32767)

	if sign then
		return value - 32768
	else
		return value
	end
end

function buffer.readi32(b: buffer_polyfill, offset: number)
	if _G.DAL_runtime_type_checking then
		if not isnumber(offset) then
			error(`invalid argument #1 to 'readi32' (number expected, got {typeof(offset)})`)
		end
	end
	local data = b[privatekey]
	local value = bor(
		bor(bor(data[offset + 1], lshift(data[offset + 2], 8)), lshift(data[offset + 3], 16)),
		lshift(data[offset + 4], 24)
	)
	local sign = btest(value, 2147483648)
	value = band(value, 2147483647)

	if sign then
		return value - 2147483648
	else
		return value
	end
end

-- float

function buffer.writef32(b: buffer_polyfill, offset: number, value: number)
	if _G.DAL_runtime_type_checking then
		if not isnumber(offset) then
			error(`invalid argument #1 to 'writef32' (number expected, got {typeof(offset)})`)
		elseif not isnumber(value) then
			error(`invalid argument #2 to 'writef32' (number expected, got {typeof(value)})`)
		end
	end
	local sign = value < 0
	value = abs(value)

	local mantissa, exponent = frexp(value)
	local data = b[privatekey]

	if value == huge then
		if sign then
			data[offset + 1] = 255 -- 11111111
		else
			data[offset + 1] = 127 -- 01111111
		end
		data[offset + 2] = 128
		data[offset + 3] = 0
		data[offset + 4] = 0
		return
	elseif value ~= value then
		data[offset + 1] = 127
		data[offset + 2] = 255
		data[offset + 3] = 255
		data[offset + 4] = 255
		return
	elseif value == 0 then
		data[offset + 1] = 0
		data[offset + 2] = 0
		data[offset + 3] = 0
		data[offset + 4] = 0
		return
	elseif exponent + 127 <= 1 then
		mantissa = floor(mantissa * 8388608 + 0.5)
		if sign then
			data[offset + 1] = 128 -- Sign bit, 7 empty bits for exponent
		else
			data[offset + 1] = 0
		end
		data[offset + 2] = rshift(mantissa, 16)
		data[offset + 3] = band(rshift(mantissa, 8), 255)
		data[offset + 3] = band(mantissa, 255)
		return
	end

	mantissa = floor((mantissa - 0.5) * 16777216 + 0.5)

	-- 127-1 = 126
	if sign then -- sign + 7 exponent
		data[offset + 1] = 128 + rshift(exponent + 126, 1)
	else
		data[offset + 1] = rshift(exponent + 126, 1)
	end

	data[offset + 2] = band(lshift(exponent + 126, 7), 255) + rshift(mantissa, 16) -- 1 exponent + 7 mantissa
	data[offset + 3] = band(rshift(mantissa, 8), 255) -- 8 mantissa
	data[offset + 4] = band(mantissa, 255) -- 8 mantissa
end

function buffer.writef64(b: buffer_polyfill, offset: number, value: number)
	if _G.DAL_runtime_type_checking then
		if not isnumber(offset) then
			error(`invalid argument #1 to 'writef64' (number expected, got {typeof(offset)})`)
		elseif not isnumber(value) then
			error(`invalid argument #2 to 'writef64' (number expected, got {typeof(value)})`)
		end
	end
	local sign = value < 0
	value = abs(value)

	local mantissa, exponent = frexp(value)
	local data = b[privatekey]

	if value == math.huge then
		if sign then
			data[offset + 1] = 255 -- 11111111
		else
			data[offset + 1] = 127 -- 01111111
		end
		data[offset + 2] = 240 -- 11110000
		data[offset + 3] = 0 -- 00000000
		data[offset + 4] = 0 -- 00000000
		data[offset + 5] = 0 -- 00000000
		data[offset + 6] = 0 -- 00000000
		data[offset + 7] = 0 -- 00000000
		data[offset + 8] = 0 -- 00000000
		return
	elseif offset ~= offset then
		-- 01111111 11111111 11111111 11111111 11111111 11111111 11111111 11111111
		data[offset + 1] = 127
		data[offset + 2] = 255
		data[offset + 3] = 255
		data[offset + 4] = 255
		data[offset + 5] = 255
		data[offset + 6] = 255
		data[offset + 7] = 255
		data[offset + 8] = 255
		return
	elseif value == 0 then
		data[offset + 1] = 0
		return
	elseif exponent + 1023 <= 1 then -- bias for doubles is 1023
		mantissa = floor(mantissa * 4503599627370496 + 0.5)
		if sign then
			data[offset + 1] = 128 -- Sign bit, 7 empty bits for exponent
		else
			data[offset + 1] = 0
		end

		-- This is labeled better below
		local leastSignificantChunk = mantissa % 0x100000000 -- 32 bits
		local mostSignificantChunk = floor(mantissa / 0x100000000) -- 20 bits

		data[offset + 2] = rshift(mostSignificantChunk, 16)
		data[offset + 3] = band(rshift(mostSignificantChunk, 8), 255)
		data[offset + 4] = band(mostSignificantChunk, 255)
		data[offset + 5] = rshift(leastSignificantChunk, 24)
		data[offset + 6] = band(rshift(leastSignificantChunk, 16), 255)
		data[offset + 7] = band(rshift(leastSignificantChunk, 8), 255)
		data[offset + 8] = band(leastSignificantChunk, 255)
		return
	end

	mantissa = floor((mantissa - 0.5) * 9007199254740992 + 0.5)

	--1023-1 = 1022
	if sign then
		data[offset + 1] = 128 + rshift(exponent + 1022, 4) -- shift out 4 of the bits in exponent
	else
		data[offset + 1] = rshift(exponent + 1022, 4) -- 01000001 0110
	end
	-- Things start to get a bit wack here because the mantissa is 52 bits, so bit32 *can't* be used.
	-- As the Offspring once said... You gotta keep 'em seperated.
	local leastSignificantChunk = mantissa % 0x100000000 -- 32 bits
	local mostSignificantChunk = floor(mantissa / 0x100000000) -- 20 bits

	-- First, the last 4 bits of the exponent and the first 4 bits of the mostSignificantChunk:
	data[offset + 2] = band(lshift(exponent + 1022, 4), 255) + rshift(mostSignificantChunk, 16)
	-- Then, the next 16 bits:
	data[offset + 3] = band(rshift(mostSignificantChunk, 8), 255)
	data[offset + 4] = band(mostSignificantChunk, 255)
	-- Then... 4 bytes of the leastSignificantChunk
	data[offset + 5] = rshift(leastSignificantChunk, 24)
	data[offset + 6] = band(rshift(leastSignificantChunk, 16), 255)
	data[offset + 7] = band(rshift(leastSignificantChunk, 8), 255)
	data[offset + 8] = band(leastSignificantChunk, 255)
end

function buffer.readf32(b: buffer_polyfill, offset: number)
	if _G.DAL_runtime_type_checking then
		if not isnumber(offset) then
			error(`invalid argument #1 to 'readf32' (number expected, got {typeof(offset)})`)
		end
	end
	local data = b[privatekey]
	local b0 = data[offset + 1]
	local b1 = data[offset + 2]
	local sign = btest(b0, 128)
	local exponent = band(lshift(b0, 1), 255) + rshift(b1, 7)
	local mantissa = lshift(band(b1, 127), 23 - 7)
		+ lshift(data[offset + 3], 23 - 7 - 8)
		+ lshift(data[offset + 4], 23 - 7 - 8 - 8)

	if exponent == 255 then -- 2^8-1
		if mantissa ~= 0 then
			return 0 / 0
		else
			return sign and -huge or huge
		end
	elseif exponent == 0 then
		if mantissa == 0 then
			return 0
		else
			-- -126 is the 0-bias+1
			return sign and -ldexp(mantissa / 8388608, -126) or ldexp(mantissa / 8388608, -126)
		end
	end

	mantissa = (mantissa / 8388608) + 1

	return sign and -ldexp(mantissa, exponent - 127) or ldexp(mantissa, exponent - 127)
end

function buffer.readf64(b: buffer_polyfill, offset: number)
	if _G.DAL_runtime_type_checking then
		if not isnumber(offset) then
			error(`invalid argument #1 to 'readf64' (number expected, got {typeof(offset)})`)
		end
	end
	local data = b[privatekey]
	local b0 = data[offset + 1]
	local b1 = data[offset + 2]

	local sign = btest(b0, 128)
	local exponent = lshift(band(b0, 127), 4) + rshift(b1, 4)
	local mostSignificantChunk = lshift(band(b1, 15), 16) + lshift(data[offset + 3], 8) + data[offset + 4]
	local leastSignificantChunk = lshift(data[offset + 5], 24)
		+ lshift(data[offset + 6], 16)
		+ lshift(data[offset + 7], 8)
		+ data[offset + 8]

	-- local mantissa = (bit32.lshift(bit32.band(b1, 15), 16)+bit32.lshift(readByte(), 8)+readByte())*0x100000000+
	--     bit32.lshift(readByte(), 24)+bit32.lshift(readByte(), 16)+bit32.lshift(readByte(), 8)+readByte()

	local mantissa = mostSignificantChunk * 0x100000000 + leastSignificantChunk

	if exponent == 2047 then -- 2^11-1
		if mantissa ~= 0 then
			return 0 / 0
		else
			return sign and -huge or huge
		end
	elseif exponent == 0 then
		if mantissa == 0 then
			return 0
		else
			return sign and -ldexp(mantissa / 4503599627370496, -1022)
				or ldexp(mantissa / 4503599627370496, -1022)
		end
	end

	mantissa = (mantissa / 4503599627370496) + 1

	return sign and -ldexp(mantissa, exponent - 1023) or ldexp(mantissa, exponent - 1023)
end

-- string

function buffer.writestring(b: buffer_polyfill, offset: number, value: string, count: number?)
	if _G.DAL_runtime_type_checking then
		if not isnumber(offset) then
			error(`invalid argument #1 to 'writestring' (number expected, got {typeof(offset)})`)
		elseif not isstring(value) then
			error(`invalid argument #2 to 'writestring' (string expected, got {typeof(value)})`)
		elseif count ~= nil and not isnumber(count) then
			error(`invalid argument #3 to 'writestring' (number expected, got {typeof(count)})`)
		end
	end
	local data = b[privatekey]
	for i = 1, count or #value do
		data[offset + i] = byte(value, i, i)
	end
end

function buffer.readstring(b: buffer_polyfill, offset: number, count: number)
	if _G.DAL_runtime_type_checking then
		if not isnumber(offset) then
			error(`invalid argument #1 to 'readstring' (number expected, got {typeof(offset)})`)
		elseif not isnumber(count) then
			error(`invalid argument #2 to 'readstring' (number expected, got {typeof(count)})`)
		end
	end
	local data = b[privatekey]
	local str = {}
	for i = 1, count do
		str[i] = chars[data[offset + i]]
	end

	return concat(str)
end

-- serdes

function buffer.tostring(b: buffer_polyfill): string
	local data = b[privatekey]
	local t = {}
	for i = #data, 1, -1 do
		t[i] = chars[data[i] + 1]
	end
	return concat(t)
end

function buffer.fromstring(str: string): buffer_polyfill
	if _G.DAL_runtime_type_checking then
		if not isstring(str) then
			error(`invalid argument #1 to 'fromstring' (string expected, got {typeof(str)})`)
		end
	end
	local data = {}
	for i = #str, 1, -1 do
		data[i] = byte(str, i, i)
	end
	return {
		[privatekey] = data
	}
end

function buffer.__tostring(self: buffer_polyfill)
	return "buffer: " .. tostring(self[privatekey]):sub(8)
end

nativetypes[buffer] = "buffer"

return buffer
