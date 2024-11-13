--!strict
-- modified https://github.com/rstk/BitBuffer
-- this is under MIT license

local table = require("./table")
local string = require("./string")
local nativetypes = require("./nativetypes")
local privatekey = require("./privatekey")
local typeof = require("./globals").typeof
local isnumber = require("./isnumber")

local getMax = math.max
local getCeil = math.ceil
local getFrexp = math.frexp
local getAbs = math.abs
local clamp = math.clamp
local round = math.round
local stringByte = string.byte
local stringUnpack = string.unpack
local stringPack = string.pack
local stringChar = string.char
local tableConcat = table.concat

local Character = table.create(256)
do
	for i = 0, 255 do
		Character[i + 1] = string.char(i)
	end
end

local BufferKey = privatekey
local SizeKey = function() end

local function writeToBuffer(this: any, index: number, size: number, value: number): ()
	local buf = this[BufferKey]

	local bit = index % 32
	local n = bit32.rshift(index, 5) + 1

	if bit + size <= 32 then
		buf[n] = bit32.replace(buf[n] or 0, value, bit, size)
	else
		local rem = 32 - bit
		buf[n] = bit32.replace(buf[n] or 0, value, bit, rem)
		buf[n + 1] = bit32.replace(buf[n + 1] or 0, bit32.extract(value, rem, size - rem), 0, size - rem)
	end

	this[SizeKey] = getMax(this[SizeKey], index)
end

local function readFromBuffer(this: any, index: number, size: number): number
	local buf = this[BufferKey]

	local bit = index % 32
	local n = bit32.rshift(index, 5) + 1

	local value = buf[n] or 0

	if bit == 0 then
		return bit32.extract(value, 0, size)
	elseif bit + size <= 32 then
		return bit32.extract(value, bit, size)
	else
		local rem = 32 - bit
		local nextValue = buf[n + 1] or 0
		return bit32.replace(bit32.extract(value, bit, rem), nextValue, rem, size - rem)
	end
end

local function writeBytesAligned(this: any, index: number, bytes: string, count: number?): ()
	local length = count or #bytes

	if length > #bytes then
		error("string length overflow")
	end

	if length < 4 then
		writeToBuffer(this, index, length * 8, (stringUnpack("<I" .. length, bytes)))
	elseif length == 4 then
		local a, b, c, d = stringByte(bytes, 1, 4)
		writeToBuffer(this, index, 32, a + b * 256 + c * 65536 + d * 16777216)
	elseif length < 8 then
		local a, b, c, d = stringByte(bytes, 1, 4)
		writeToBuffer(this, index, 32, a + b * 256 + c * 65536 + d * 16777216)
		writeToBuffer(this, index, length * 8 - 32, (stringUnpack("<I" .. length - 4, bytes, 5)))
	else
		local buf = this[BufferKey]
		local bit = index % 32
		local n = bit32.rshift(index, 5) + 1
		local offset = 0

		if bit ~= 0 then
			offset = 4 - bit / 8
			writeToBuffer(this, index, 32 - bit, (stringUnpack("<I" .. offset, bytes)))
			n += 1
		end

		for i = offset + 4, length, 4 do
			local a, b, c, d = stringByte(bytes, i - 3, i)
			buf[n] = a + b * 256 + c * 65536 + d * 16777216
			n += 1
		end

		local rem = (length - offset - 4) % 4
		if rem > 0 then
			local v = stringUnpack("<I" .. rem, bytes, length - rem + 1)
			buf[n] = bit32.replace(buf[n] or 0, v, 0, rem * 8)
		end
	end
end

local function readBytesAligned(this: any, index: number, length: number): string
	if length < 4 then
		return stringPack("<I" .. length, readFromBuffer(this, index, length * 8))
	elseif length == 4 then
		local value = readFromBuffer(this, index, 32)
		return stringChar(
			bit32.extract(value, 0, 8),
			bit32.extract(value, 8, 8),
			bit32.extract(value, 16, 8),
			bit32.extract(value, 24, 8)
		)
	end

	local prefix = 3 - (index / 8 - 1) % 4
	local suffix = (length - prefix) % 4
	local t = (length - prefix - suffix) / 4
	local o = 0
	local str = table.create(t + 2)

	if prefix > 0 then
		str[1] = stringPack("<I" .. prefix, readFromBuffer(this, index, prefix * 8))
		o = 1
	end

	local buf = this[BufferKey]
	local n = bit32.rshift(index, 5) + 1
	for i = 1, t do
		local value = buf[n + i - 1] or 0
		str[o + i] = stringChar(
			bit32.extract(value, 0, 8),
			bit32.extract(value, 8, 8),
			bit32.extract(value, 16, 8),
			bit32.extract(value, 24, 8)
		)
	end

	if suffix > 0 then
		str[o + t + 1] = stringPack("<I" .. suffix, bit32.extract(buf[n + t] or 0, 0, suffix * 8))
	end

	return tableConcat(str)
end

local buffer = {}

function buffer:__tostring()
	return "buffer: " .. tostring(self[BufferKey]):sub(8)
end

function buffer.create(size: number)
	if _G.DAL_runtime_type_checking then
		if not isnumber(size) then
			error(`invalid argument #1 to 'create' (number expected, got {typeof(size)})`)
		end
	end

	size *= 8
	return setmetatable({
		[BufferKey] = table.create(math.ceil(size / 32)),
		[SizeKey] = size :: any,
	}, buffer)
end

function buffer.fromstring(str: string)
	if _G.DAL_runtime_type_checking then
		if type(str) ~= "string" then
			error(`invalid argument #1 to 'fromstring' (string expected, got {typeof(string)})`)
		end
	end

	local length = #str
	local buf = table.create(math.ceil(length / 4))
	for i = 1, length / 4 do
		local a, b, c, d = stringByte(str, i * 4 - 3, i * 4)
		buf[i] = a + b * 256 + c * 65536 + d * 16777216
	end

	local rem = length % 4
	if rem ~= 0 then
		buf[getCeil(length / 4)] = stringUnpack("<I" .. rem, str, length - rem)
	end

	return setmetatable({
		[BufferKey] = buf,
		[SizeKey] = #str * 8 :: any,
	}, buffer)
end

function buffer.tostring(b): string
	if _G.DAL_runtime_type_checking then
		if typeof(b) ~= "buffer" then
			error(`invalid argument #1 to 'tostring' (buffer expected, got {typeof(b)})`)
		end
	end

	local bufSize = #b[BufferKey]
	if bufSize == 0 then
		return ""
	end

	local str = readBytesAligned(b, 0, bufSize * 4)
	return str
end

function buffer.writeu8(b, offset: number, uint: number): ()
	if _G.DAL_runtime_type_checking then
		if typeof(b) ~= "buffer" then
			error(`invalid argument #1 to 'writeu8' (buffer expected, got {typeof(b)})`)
		elseif not isnumber(offset) then
			error(`invalid argument #2 to 'writeu8' (number expected, got {typeof(offset)})`)
		elseif not isnumber(uint) then
			error(`invalid argument #3 to 'writeu8' (number expected, got {typeof(uint)})`)
		end
	end
	offset *= 8
	writeToBuffer(b, offset, 8, uint)
end

function buffer.writeu16(b, offset: number, uint: number): ()
	if _G.DAL_runtime_type_checking then
		if typeof(b) ~= "buffer" then
			error(`invalid argument #1 to 'writeu16' (buffer expected, got {typeof(b)})`)
		elseif not isnumber(offset) then
			error(`invalid argument #2 to 'writeu16' (number expected, got {typeof(offset)})`)
		elseif not isnumber(uint) then
			error(`invalid argument #3 to 'writeu16' (number expected, got {typeof(uint)})`)
		end
	end
	offset *= 8
	writeToBuffer(b, offset, 16, uint)
end

function buffer.writeu32(b, offset: number, uint: number): ()
	if _G.DAL_runtime_type_checking then
		if typeof(b) ~= "buffer" then
			error(`invalid argument #1 to 'writeu32' (buffer expected, got {typeof(b)})`)
		elseif not isnumber(offset) then
			error(`invalid argument #2 to 'writeu32' (number expected, got {typeof(offset)})`)
		elseif not isnumber(uint) then
			error(`invalid argument #3 to 'writeu32' (number expected, got {typeof(uint)})`)
		end
	end
	offset *= 8
	writeToBuffer(b, offset, 32, uint)
end

function buffer.readu8(b, offset: number): number
	if _G.DAL_runtime_type_checking then
		if typeof(b) ~= "buffer" then
			error(`invalid argument #1 to 'readu8' (buffer expected, got {typeof(b)})`)
		elseif not isnumber(offset) then
			error(`invalid argument #2 to 'readu8' (number expected, got {typeof(offset)})`)
		end
	end
	offset *= 8
	return readFromBuffer(b, offset, 8)
end

function buffer.readu16(b, offset: number): number
	if _G.DAL_runtime_type_checking then
		if typeof(b) ~= "buffer" then
			error(`invalid argument #1 to 'readu16' (buffer expected, got {typeof(b)})`)
		elseif not isnumber(offset) then
			error(`invalid argument #2 to 'readu16' (number expected, got {typeof(offset)})`)
		end
	end
	offset *= 8
	return readFromBuffer(b, offset, 16)
end

function buffer.readu32(b, offset: number): number
	if _G.DAL_runtime_type_checking then
		if typeof(b) ~= "buffer" then
			error(`invalid argument #1 to 'readu32' (buffer expected, got {typeof(b)})`)
		elseif not isnumber(offset) then
			error(`invalid argument #2 to 'readu32' (number expected, got {typeof(offset)})`)
		end
	end
	offset *= 8
	return readFromBuffer(b, offset, 32)
end

function buffer.writei8(b, offset: number, int: number)
	if _G.DAL_runtime_type_checking then
		if typeof(b) ~= "buffer" then
			error(`invalid argument #1 to 'writei8' (buffer expected, got {typeof(b)})`)
		elseif not isnumber(offset) then
			error(`invalid argument #2 to 'writei8' (number expected, got {typeof(offset)})`)
		elseif not isnumber(int) then
			error(`invalid argument #3 to 'writei8' (number expected, got {typeof(int)})`)
		end
	end
	offset *= 8
	local bitWidth = 8
	writeToBuffer(b, offset, bitWidth, int % (bit32.lshift(1, bitWidth - 1) * 2))
end

function buffer.writei16(b, offset: number, int: number)
	if _G.DAL_runtime_type_checking then
		if typeof(b) ~= "buffer" then
			error(`invalid argument #1 to 'writei16' (buffer expected, got {typeof(b)})`)
		elseif not isnumber(offset) then
			error(`invalid argument #2 to 'writei16' (number expected, got {typeof(offset)})`)
		elseif not isnumber(int) then
			error(`invalid argument #3 to 'writei16' (number expected, got {typeof(int)})`)
		end
	end
	offset *= 8
	local bitWidth = 16
	writeToBuffer(b, offset, bitWidth, int % (bit32.lshift(1, bitWidth - 1) * 2))
end

function buffer.writei32(b, offset: number, int: number)
	if _G.DAL_runtime_type_checking then
		if typeof(b) ~= "buffer" then
			error(`invalid argument #1 to 'writei32' (buffer expected, got {typeof(b)})`)
		elseif not isnumber(offset) then
			error(`invalid argument #2 to 'writei32' (number expected, got {typeof(offset)})`)
		elseif not isnumber(int) then
			error(`invalid argument #3 to 'writei32' (number expected, got {typeof(int)})`)
		end
	end
	offset *= 8
	local bitWidth = 32
	writeToBuffer(b, offset, bitWidth, int % (bit32.lshift(1, bitWidth - 1) * 2))
end

function buffer.readi8(b, offset: number): number
	if _G.DAL_runtime_type_checking then
		if typeof(b) ~= "buffer" then
			error(`invalid argument #1 to 'readi8' (buffer expected, got {typeof(b)})`)
		elseif not isnumber(offset) then
			error(`invalid argument #2 to 'readi8' (number expected, got {typeof(offset)})`)
		end
	end
	offset *= 8
	local bitWidth = 8
	local value = readFromBuffer(b, offset, bitWidth)
	local max = if bitWidth == 32 then 4294967296 else bit32.lshift(1, bitWidth)
	return if value >= max / 2 then value - max else value
end

function buffer.readi16(b, offset: number): number
	if _G.DAL_runtime_type_checking then
		if typeof(b) ~= "buffer" then
			error(`invalid argument #1 to 'readi16' (buffer expected, got {typeof(b)})`)
		elseif not isnumber(offset) then
			error(`invalid argument #2 to 'readi16' (number expected, got {typeof(offset)})`)
		end
	end
	offset *= 8
	local bitWidth = 16
	local value = readFromBuffer(b, offset, bitWidth)
	local max = if bitWidth == 32 then 4294967296 else bit32.lshift(1, bitWidth)
	return if value >= max / 2 then value - max else value
end

function buffer.readi32(b, offset: number): number
	if _G.DAL_runtime_type_checking then
		if typeof(b) ~= "buffer" then
			error(`invalid argument #1 to 'readi32' (buffer expected, got {typeof(b)})`)
		elseif not isnumber(offset) then
			error(`invalid argument #2 to 'readi32' (number expected, got {typeof(offset)})`)
		end
	end
	offset *= 8
	local bitWidth = 32
	local value = readFromBuffer(b, offset, bitWidth)
	local max = if bitWidth == 32 then 4294967296 else bit32.lshift(1, bitWidth)
	return if value >= max / 2 then value - max else value
end

function buffer.writestring(b, offset: number, bytes: string, count: number?): ()
	if _G.DAL_runtime_type_checking then
		if typeof(b) ~= "buffer" then
			error(`invalid argument #1 to 'writestring' (buffer expected, got {typeof(b)})`)
		elseif not isnumber(offset) then
			error(`invalid argument #2 to 'writestring' (number expected, got {typeof(offset)})`)
		elseif not isnumber(bytes) then
			error(`invalid argument #3 to 'writestring' (number expected, got {typeof(bytes)})`)
		elseif count and not isnumber(count) then
			error(`invalid argument #4 to 'writestring' (number or nil expected, got {typeof(count)})`)
		end
	end
	offset *= 8
	if bytes == "" then
		return
	end
	writeBytesAligned(b, offset, bytes, count)
end

function buffer.readstring(b, offset: number, count: number): string
	if _G.DAL_runtime_type_checking then
		if typeof(b) ~= "buffer" then
			error(`invalid argument #1 to 'readstring' (buffer expected, got {typeof(b)})`)
		elseif not isnumber(offset) then
			error(`invalid argument #2 to 'readstring' (number expected, got {typeof(offset)})`)
		elseif not isnumber(count) then
			error(`invalid argument #3 to 'readstring' (number expected, got {typeof(count)})`)
		end
	end
	offset *= 8
	if count <= 0 then
		return ""
	end
	return readBytesAligned(b, offset, count)
end

local POS_INF = math.huge
local NEG_INF = -POS_INF

local BINARY_POS_INF = 0b01111111100000000000000000000000
local BINARY_NEG_INF = 0b11111111100000000000000000000000
local BINARY_NAN = 0b01111111111111111111111111111111

function buffer.writef32(b, offset: number, float: number): ()
	if _G.DAL_runtime_type_checking then
		if typeof(b) ~= "buffer" then
			error(`invalid argument #1 to 'writef32' (buffer expected, got {typeof(b)})`)
		elseif not isnumber(offset) then
			error(`invalid argument #2 to 'writef32' (number expected, got {typeof(offset)})`)
		elseif not isnumber(float) then
			error(`invalid argument #3 to 'writef32' (number expected, got {typeof(float)})`)
		end
	end

	offset *= 8
	if float == 0 then
		writeToBuffer(b, offset, 32, 0)
	elseif float == POS_INF then
		writeToBuffer(b, offset, 32, BINARY_POS_INF)
	elseif float == NEG_INF then
		writeToBuffer(b, offset, 32, BINARY_NEG_INF)
	elseif float ~= float then
		writeToBuffer(b, offset, 32, BINARY_NAN)
	else
		local mantissa, exponent = getFrexp(getAbs(float))
		mantissa = round((mantissa - 0.5) * 16777216)
		exponent = clamp(exponent, -127, 128) + 127
		local sign = if float >= 0 then 0 else 2147483648
		writeToBuffer(b, offset, 32, sign + exponent * 8388608 + mantissa)
	end
end

function buffer.readf32(b, offset: number): number
	if _G.DAL_runtime_type_checking then
		if typeof(b) ~= "buffer" then
			error(`invalid argument #1 to 'readf32' (buffer expected, got {typeof(b)})`)
		elseif not isnumber(offset) then
			error(`invalid argument #2 to 'readf32' (number expected, got {typeof(offset)})`)
		end
	end

	offset *= 8
	local value = readFromBuffer(b, offset, 32)

	if value == 0 then
		return 0
	elseif value == BINARY_POS_INF then
		return POS_INF
	elseif value == BINARY_NEG_INF then
		return NEG_INF
	elseif value == BINARY_NAN then
		return 0 / 0
	end

	local sign = if bit32.band(value, 2147483648) == 0 then 1 else -1
	local exponent = bit32.extract(value, 23, 8) - 127
	local mantissa = value % 8388608
	return sign * (mantissa / 8388608 * 0.5 + 0.5) * math.pow(2, exponent)
end

function buffer.writef64(this, offset, double: number): ()
	if _G.DAL_runtime_type_checking then
		if typeof(this) ~= "buffer" then
			error(`invalid argument #1 to 'writef64' (buffer expected, got {typeof(this)})`)
		elseif not isnumber(offset) then
			error(`invalid argument #2 to 'writef64' (number expected, got {typeof(offset)})`)
		elseif not isnumber(double) then
			error(`invalid argument #3 to 'writef64' (number expected, got {typeof(double)})`)
		end
	end

	local a, b, c, d, e, f, g, h = stringByte(stringPack("<d", double), 1, 8)
	writeToBuffer(this, offset, 32, a + b * 256 + c * 65536 + d * 16777216)
	writeToBuffer(this, offset, 32, e + f * 256 + g * 65536 + h * 16777216)
end

function buffer.readf64(this, offset): number
	if _G.DAL_runtime_type_checking then
		if typeof(this) ~= "buffer" then
			error(`invalid argument #1 to 'readf64' (buffer expected, got {typeof(this)})`)
		elseif not isnumber(offset) then
			error(`invalid argument #2 to 'readf64' (number expected, got {typeof(offset)})`)
		end
	end

	local a = readFromBuffer(this, offset, 32)
	local b = readFromBuffer(this, offset, 32)

	return (
		stringUnpack(
			"<d",
			stringChar(
				bit32.band(a, 255),
				bit32.extract(a, 8, 8),
				bit32.extract(a, 16, 8),
				bit32.extract(a, 24, 8),
				bit32.band(b, 255),
				bit32.extract(b, 8, 8),
				bit32.extract(b, 16, 8),
				bit32.extract(b, 24, 8)
			)
		)
	)
end

nativetypes[buffer] = "buffer"

return table.freeze(buffer) :: typeof(buffer)
