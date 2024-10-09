--!strict
-- modified https://github.com/rstk/BitBuffer
-- this is under MIT license

local table = require("./table")
local bit32 = require("./bit32")
local string = require("./string")
local nativetypes = require("./nativetypes")

local Character = table.create(256)
do
	for i = 0, 255 do
		Character[i + 1] = string.char(i)
	end
end

local BufferKey = function() end
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

	this[SizeKey] = math.max(this[SizeKey], index)
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
		writeToBuffer(this, index, length * 8, (string.unpack("<I" .. length, bytes)))
	elseif length == 4 then
		local a, b, c, d = string.byte(bytes, 1, 4)
		writeToBuffer(this, index, 32, a + b * 256 + c * 65536 + d * 16777216)
	elseif length < 8 then
		local a, b, c, d = string.byte(bytes, 1, 4)
		writeToBuffer(this, index, 32, a + b * 256 + c * 65536 + d * 16777216)
		writeToBuffer(this, index, length * 8 - 32, (string.unpack("<I" .. length - 4, bytes, 5)))
	else
		local buf = this[BufferKey]
		local bit = index % 32
		local n = bit32.rshift(index, 5) + 1
		local offset = 0

		if bit ~= 0 then
			offset = 4 - bit / 8
			writeToBuffer(this, index, 32 - bit, (string.unpack("<I" .. offset, bytes)))
			n += 1
		end

		for i = offset + 4, length, 4 do
			local a, b, c, d = string.byte(bytes, i - 3, i)
			buf[n] = a + b * 256 + c * 65536 + d * 16777216
			n += 1
		end

		local rem = (length - offset - 4) % 4
		if rem > 0 then
			local v = string.unpack("<I" .. rem, bytes, length - rem + 1)
			buf[n] = bit32.replace(buf[n] or 0, v, 0, rem * 8)
		end
	end
end

local function readBytesAligned(this: any, index: number, length: number): string
	if length < 4 then
		return string.pack("<I" .. length, readFromBuffer(this, index, length * 8))
	elseif length == 4 then
		local value = readFromBuffer(this, index, 32)
		return string.char(bit32.extract(value, 0, 8), bit32.extract(value, 8, 8), bit32.extract(value, 16, 8), bit32.extract(value, 24, 8))
	end

	local prefix = 3 - (index / 8 - 1) % 4
	local suffix = (length - prefix) % 4
	local t = (length - prefix - suffix) / 4
	local o = 0
	local str = table.create(t + 2)

	if prefix > 0 then
		str[1] = string.pack("<I" .. prefix, readFromBuffer(this, index, prefix * 8))
		o = 1
	end

	local buf = this[BufferKey]
	local n = bit32.rshift(index, 5) + 1
	for i = 1, t do
		local value = buf[n + i - 1] or 0
		str[o + i] = string.char(bit32.extract(value, 0, 8), bit32.extract(value, 8, 8), bit32.extract(value, 16, 8), bit32.extract(value, 24, 8))
	end

	if suffix > 0 then
		str[o + t + 1] = string.pack("<I" .. suffix, bit32.extract(buf[n + t] or 0, 0, suffix * 8))
	end

	return table.concat(str)
end

local buffer = {}

function buffer:__tostring()
	return "buffer: " .. tostring(self[BufferKey]):sub(8)
end

function buffer.create(size: number)
	size *= 8
	return setmetatable({
		[BufferKey] = table.create(math.ceil(size / 32)),
		[SizeKey] = size :: any
	}, buffer)
end

function buffer.fromstring(str: string)
	-- if type(str) ~= "string" then
	-- 	error(`invalid argument #1 to 'fromstring' (string expected, got {typeof(str)})`)
	-- end

	local length = #str
	local buf = table.create(math.ceil(length / 4))
	for i = 1, length / 4 do
		local a, b, c, d = string.byte(str, i * 4 - 3, i * 4)
		buf[i] = a + b * 256 + c * 65536 + d * 16777216
	end

	local rem = length % 4
	if rem ~= 0 then
		buf[math.ceil(length / 4)] = string.unpack("<I" .. rem, str, length - rem)
	end

	return setmetatable({
		[BufferKey] = buf,
		[SizeKey] = #str * 8 :: any
	}, buffer)
end

function buffer.tostring(b): string
	local bufSize = #b[BufferKey]
	if bufSize == 0 then
		return ""
	end

	local str = readBytesAligned(b, 0, bufSize * 4)
	return str
end

function buffer.writeu8(b, offset: number, uint: number): ()
	offset *= 8
	writeToBuffer(b, offset, 8, uint)
end

function buffer.writeu16(b, offset: number, uint: number): ()
	offset *= 8
	writeToBuffer(b, offset, 16, uint)
end

function buffer.writeu32(b, offset: number, uint: number): ()
	offset *= 8
	writeToBuffer(b, offset, 32, uint)
end

function buffer.readu8(b, offset: number): number
	offset *= 8
	return readFromBuffer(b, offset, 8)
end

function buffer.readu16(b, offset: number): number
	offset *= 8
	return readFromBuffer(b, offset, 16)
end

function buffer.readu32(b, offset: number): number
	offset *= 8
	return readFromBuffer(b, offset, 32)
end

function buffer.writei8(b, offset: number, int: number)
	-- if type(int) ~= "number" then
	-- 	error(`invalid argument #3 to 'readi8' (number expected, got {typeof(int)})`)
	-- end
	offset *= 8
	local bitWidth = 8
	writeToBuffer(b, offset, bitWidth, int % (bit32.lshift(1, bitWidth - 1) * 2))
end

function buffer.writei16(b, offset: number, int: number)
	-- if type(int) ~= "number" then
	-- 	error(`invalid argument #3 to 'readi16' (number expected, got {typeof(int)})`)
	-- end
	offset *= 8
	local bitWidth = 16
	writeToBuffer(b, offset, bitWidth, int % (bit32.lshift(1, bitWidth - 1) * 2))
end

function buffer.writei32(b, offset: number, int: number)
	-- if type(int) ~= "number" then
	-- 	error(`invalid argument #3 to 'readi8' (number expected, got {typeof(int)})`)
	-- end
	offset *= 8
	local bitWidth = 32
	writeToBuffer(b, offset, bitWidth, int % (bit32.lshift(1, bitWidth - 1) * 2))
end

function buffer.readi8(b, offset: number): number
	offset *= 8
	local bitWidth = 8
	local value = readFromBuffer(b, offset, bitWidth)
	local max = if bitWidth == 32 then 4294967296 else bit32.lshift(1, bitWidth)
	return if value >= max / 2 then value - max else value
end

function buffer.readi16(b, offset: number): number
	offset *= 8
	local bitWidth = 16
	local value = readFromBuffer(b, offset, bitWidth)
	local max = if bitWidth == 32 then 4294967296 else bit32.lshift(1, bitWidth)
	return if value >= max / 2 then value - max else value
end

function buffer.readi32(b, offset: number): number
	offset *= 8
	local bitWidth = 32
	local value = readFromBuffer(b, offset, bitWidth)
	local max = if bitWidth == 32 then 4294967296 else bit32.lshift(1, bitWidth)
	return if value >= max / 2 then value - max else value
end

function buffer.writestring(this, offset: number, bytes: string, count: number?): ()
	offset *= 8
	if bytes == "" then
		return
	end
	writeBytesAligned(this, offset, bytes, count)
end

function buffer.readstring(this, offset: number, count: number): string
	offset *= 8
	if count <= 0 then
		return ""
	end
	return readBytesAligned(this, offset, count)
end

local POS_INF = math.huge
local NEG_INF = -POS_INF

local BINARY_POS_INF = 0b01111111100000000000000000000000
local BINARY_NEG_INF = 0b11111111100000000000000000000000
local BINARY_NAN = 0b01111111111111111111111111111111

function buffer.writef32(b, offset: number, float: number): ()
	-- if type(float) ~= "number" then
	-- 	error(`invalid argument #3 to 'writef32' (number expected, got {typeof(float)})`)
	-- end

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
		local mantissa, exponent = math.frexp(math.abs(float))
		mantissa = math.round((mantissa - 0.5) * 16777216)
		exponent = math.clamp(exponent, -127, 128) + 127
		local sign = if float >= 0 then 0 else 2147483648
		writeToBuffer(b, offset, 32, sign + exponent * 8388608 + mantissa)
	end
end

function buffer.readf32(b, offset: number): number
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
	-- if type(double) ~= "number" then
	-- 	error(`invalid argument #3 to 'writef64' (number expected, got {typeof(double)})`)
	-- end

	local a, b, c, d, e, f, g, h = string.byte(string.pack("<d", double), 1, 8)
	writeToBuffer(this, offset, 32, a + b * 256 + c * 65536 + d * 16777216)
	writeToBuffer(this, offset, 32, e + f * 256 + g * 65536 + h * 16777216)
end

function buffer.readf64(this, offset): number
	local a = readFromBuffer(this, offset, 32)
	local b = readFromBuffer(this, offset, 32)

	return (
			string.unpack(
				"<d",
				string.char(
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
