local perlin = require("./perlin")
local typeof = require("./globals").typeof
local isnumber = require("./isnumber")

local getmax = math.max
local getmin = math.min
local exp = math.exp
local abs = math.abs
local floor = math.floor
local log = math.log
local log2 = log(2)
local math_atan = math.atan

local function atan(a: number): number
	if _G.DAL_runtime_type_checking then
		if not isnumber(a) then
			error(`invalid argument #1 to 'atan' (number expected, got {typeof(a)})`)
		end
	end
	return math_atan(a)
end

local function atan2(a: number, b: number): number
	if _G.DAL_runtime_type_checking then
		if not isnumber(a) then
			error(`invalid argument #1 to 'atan2' (number expected, got {typeof(a)})`)
		elseif not isnumber(b) then
			error(`invalid argument #2 to 'atan2' (number expected, got {typeof(b)})`)
		end
	end
	return (math_atan :: any)(a, b)
end

local function clamp(v: number, min: number, max: number): number
	if _G.DAL_runtime_type_checking then
		if not isnumber(v) then
			error(`invalid argument #1 to 'clamp' (number expected, got {typeof(v)})`)
		elseif not isnumber(min) then
			error(`invalid argument #2 to 'clamp' (number expected, got {typeof(min)})`)
		elseif not isnumber(max) then
			error(`invalid argument #3 to 'clamp' (number expected, got {typeof(max)})`)
		end
	end

	if min > max then
		error("max must be greater than or equal to min")
	end

	return getmax(min, getmin(v, max))
end

local function cosh(x: number): number
	if _G.DAL_runtime_type_checking then
		if not isnumber(x) then
			error(`invalid argument #1 to 'cosh' (number expected, got {typeof(x)})`)
		end
	end
	if x == 0.0 then
		return 1.0
	end
	if x < 0.0 then
		x = -x
	end
	x = exp(x)
	x = x / 2.0 + 0.5 / x
	return x
end

local function sinh(x: number): number
	if _G.DAL_runtime_type_checking then
		if not isnumber(x) then
			error(`invalid argument #1 to 'sinh' (number expected, got {typeof(x)})`)
		end
	end
	if x == 0 then
		return 0.0
	end
	local neg = false
	if x < 0 then
		x = -x
		neg = true
	end
	if x < 1.0 then
		local y = x * x
		x = x
			+ x
				* y
				* (((-0.78966127417357099479e0 * y + -0.16375798202630751372e3) * y + -0.11563521196851768270e5) * y + -0.35181283430177117881e6)
				/ (((0.10000000000000000000e1 * y + -0.27773523119650701667e3) * y + 0.36162723109421836460e5) * y + -0.21108770058106271242e7)
	else
		x = exp(x)
		x = x / 2.0 - 0.5 / x
	end
	if neg then
		x = -x
	end
	return x
end

local function tanh(x: number): number
	if _G.DAL_runtime_type_checking then
		if not isnumber(x) then
			error(`invalid argument #1 to 'tanh' (number expected, got {typeof(x)})`)
		end
	end
	if x == 0 then
		return 0.0
	end
	local neg = false
	if x < 0 then
		x = -x
		neg = true
	end
	if x < 0.54930614433405 then
		local y = x * x
		x = x
			+ x
				* y
				* ((-0.96437492777225469787e0 * y + -0.99225929672236083313e2) * y + -0.16134119023996228053e4)
				/ (((0.10000000000000000000e1 * y + 0.11274474380534949335e3) * y + 0.22337720718962312926e4) * y + 0.48402357071988688686e4)
	else
		x = exp(x)
		x = 1.0 - 2.0 / (x * x + 1.0)
	end
	if neg then
		x = -x
	end
	return x
end

local function pow(a: number, b: number): number
	if _G.DAL_runtime_type_checking then
		if not isnumber(a) then
			error(`invalid argument #1 to 'pow' (number expected, got {typeof(a)})`)
		elseif not isnumber(b) then
			error(`invalid argument #2 to 'pow' (number expected, got {typeof(b)})`)
		end
	end
	return a ^ b
end

local function frexp(x: number): (number, number)
	if _G.DAL_runtime_type_checking then
		if not isnumber(x) then
			error(`invalid argument #1 to 'frexp' (number expected, got {typeof(x)})`)
		end
	end
	if x == 0 then
		return 0.0, 0.0
	end
	local e = floor(log(abs(x)) / log2)
	if e > 0 then
		x = x * 2 ^ -e
	else
		x = x / 2 ^ e
	end
	if abs(x) >= 1.0 then
		x, e = x / 2, e + 1
	end
	return x, e
end

local function ldexp(x: number, e: number): number
	if _G.DAL_runtime_type_checking then
		if not isnumber(x) then
			error(`invalid argument #1 to 'ldexp' (number expected, got {typeof(x)})`)
		elseif not isnumber(e) then
			error(`invalid argument #2 to 'ldexp' (number expected, got {typeof(e)})`)
		end
	end
	return x * 2 ^ e
end

local function log10(x): number
	if _G.DAL_runtime_type_checking then
		if not isnumber(x) then
			error(`invalid argument #1 to 'log10' (number expected, got {typeof(x)})`)
		end
	end
	return log(x) / log(10)
end

local function round(n: number): number
	if _G.DAL_runtime_type_checking then
		if not isnumber(n) then
			error(`invalid argument #1 to 'round' (number expected, got {typeof(n)})`)
		end
	end
	return floor((floor(n * 2) + 1) / 2)
end

local function sign(n): number
	if _G.DAL_runtime_type_checking then
		if not isnumber(n) then
			error(`invalid argument #1 to 'sign' (number expected, got {typeof(n)})`)
		end
	end
	if n > 0 then
		return 1
	elseif n < 0 then
		return -1
	else
		return 0
	end
end

return {
	atan = atan,
	atan2 = atan2,
	clamp = clamp,
	cosh = cosh,
	sinh = sinh,
	tanh = tanh,
	pow = pow,
	noise = perlin,
	frexp = frexp,
	ldexp = ldexp,
	log10 = log10,
	round = round,
	sign = sign,
	abs = math.abs,
	acos = math.acos,
	asin = math.asin,
	ceil = math.ceil,
	cos = math.cos,
	deg = math.deg,
	exp = math.exp,
	floor = math.floor,
	fmod = math.fmod,
	huge = math.huge,
	log = math.log,
	max = math.max,
	min = math.min,
	modf = math.modf,
	pi = math.pi,
	rad = math.rad,
	random = math.random,
	randomseed = math.randomseed,
	sin = math.sin,
	sqrt = math.sqrt,
	tan = math.tan,
} :: typeof(math)
