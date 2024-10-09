--!nocheck

local bit32 = {} :: typeof(bit32)

local function toUnsigned32(n)
    return n & 0xFFFFFFFF
end

function bit32.band(a, b)
	return toUnsigned32(a & b)
end

function bit32.bor(a, b)
	return toUnsigned32(a | b)
end

function bit32.bxor(a, b)
	return toUnsigned32(a ~ b)
end

function bit32.bnot(a)
	return toUnsigned32(~a)
end

function bit32.lshift(a, n)
	return toUnsigned32(a << n)
end

function bit32.rshift(a, n)
	return toUnsigned32(a >> n)
end

function bit32.arshift(a, n)
	return toUnsigned32(a >> n)
end

function bit32.lrotate(a, n)
	return toUnsigned32((a << n) | (a >> (32 - n)))
end

function bit32.rrotate(a, n)
	return toUnsigned32((a >> n) | (a << (32 - n)))
end

function bit32.extract(a, field, width)
	width = width or 1
	return toUnsigned32((a >> field) & ((1 << width) - 1))
end

function bit32.replace(a, v, field, width)
	width = width or 1
	local mask = ((1 << width) - 1) << field
	return toUnsigned32((a & ~mask) | ((v << field) & mask))
end

function bit32.byteswap(a)
	return toUnsigned32(((a & 0xFF) << 24) | ((a & 0xFF00) << 8) | ((a & 0xFF0000) >> 8) | ((a >> 24) & 0xFF))
end

function bit32.btest(a, b)
	return toUnsigned32(a & b) ~= 0
end

function bit32.countlz(x)
	if x == 0 then return 32 end
	local n = 0
	if (x & 0xFFFF0000) == 0 then n = n + 16; x = x << 16 end
	if (x & 0xFF000000) == 0 then n = n + 8;  x = x << 8  end
	if (x & 0xF0000000) == 0 then n = n + 4;  x = x << 4  end
	if (x & 0xC0000000) == 0 then n = n + 2;  x = x << 2  end
	if (x & 0x80000000) == 0 then n = n + 1 end
	return toUnsigned32(n)
end

function bit32.countrz(x)
	if x == 0 then return 32 end
	local n = 0
	if (x & 0x0000FFFF) == 0 then n = n + 16; x = x >> 16 end
	if (x & 0x000000FF) == 0 then n = n + 8;  x = x >> 8  end
	if (x & 0x0000000F) == 0 then n = n + 4;  x = x >> 4  end
	if (x & 0x00000003) == 0 then n = n + 2;  x = x >> 2  end
	if (x & 0x00000001) == 0 then n = n + 1 end
	return toUnsigned32(n)
end

return bit32 :: typeof(bit32)
