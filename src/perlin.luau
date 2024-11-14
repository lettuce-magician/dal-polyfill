--[[
    Implemented as described here:
    http://flafla2.github.io/2014/08/09/perlinnoise.html
]]
--

local floor = math.floor
local band = bit32.band

-- stylua: ignore
local kPerlinHash = {
	151, 160, 137, 91,  90,  15,  131, 13,  201, 95,  96,  53,  194, 233, 7,   225, 140, 36,  103, 30,  69,  142, 8,   99,  37,  240, 21,  10,  23,
    190, 6,   148, 247, 120, 234, 75,  0,   26,  197, 62,  94,  252, 219, 203, 117, 35,  11,  32,  57,  177, 33,  88,  237, 149, 56,  87,  174, 20,
    125, 136, 171, 168, 68,  175, 74,  165, 71,  134, 139, 48,  27,  166, 77,  146, 158, 231, 83,  111, 229, 122, 60,  211, 133, 230, 220, 105, 92,
    41,  55,  46,  245, 40,  244, 102, 143, 54,  65,  25,  63,  161, 1,   216, 80,  73,  209, 76,  132, 187, 208, 89,  18,  169, 200, 196, 135, 130,
    116, 188, 159, 86,  164, 100, 109, 198, 173, 186, 3,   64,  52,  217, 226, 250, 124, 123, 5,   202, 38,  147, 118, 126, 255, 82,  85,  212, 207,
    206, 59,  227, 47,  16,  58,  17,  182, 189, 28,  42,  223, 183, 170, 213, 119, 248, 152, 2,   44,  154, 163, 70,  221, 153, 101, 155, 167, 43,
    172, 9,   129, 22,  39,  253, 19,  98,  108, 110, 79,  113, 224, 232, 178, 185, 112, 104, 218, 246, 97,  228, 251, 34,  242, 193, 238, 210, 144,
    12,  191, 179, 162, 241, 81,  51,  145, 235, 249, 14,  239, 107, 49,  192, 214, 31,  181, 199, 106, 157, 184, 84,  204, 176, 115, 121, 50,  45,
    127, 4,   150, 254, 138, 236, 205, 93,  222, 114, 67,  29,  24,  72,  243, 141, 128, 195, 78,  66,  215, 61,  156, 180, 151
}

local kPerlinGrad = {
	{ 1, 1, 0 },
	{ -1, 1, 0 },
	{ 1, -1, 0 },
	{ -1, -1, 0 },
	{ 1, 0, 1 },
	{ -1, 0, 1 },
	{ 1, 0, -1 },
	{ -1, 0, -1 },
	{ 0, 1, 1 },
	{ 0, -1, 1 },
	{ 0, 1, -1 },
	{ 0, -1, -1 },
	{ 1, 1, 0 },
	{ 0, -1, 1 },
	{ -1, 1, 0 },
	{ 0, -1, -1 },
}

local function perlin_grad(hash, x, y, z): number
	local g = kPerlinGrad[bit32.band(hash, 15) + 1]
	return g[1] * x + g[2] * y + g[3] * z
end

local function perlin_fade(t: number): number
	return t * t * t * (t * (t * 6 - 15) + 10)
end

local function perlin_lerp(t: number, a: number, b: number): number
	return a + t * (b - a)
end

return function(x: number, y0: number?, z0: number?): number
	local y = y0 or 0
	local z = z0 or 0

	local xi = band(floor(x), 255)
	local yi = band(floor(y), 255)
	local zi = band(floor(z), 255)

	x = x - floor(x)
	y = y - floor(y)
	z = z - floor(z)

	local u = perlin_fade(x)
	local v = perlin_fade(y)
	local w = perlin_fade(z)

	local p = kPerlinHash
	local A, AA, AB, AAA, ABA, AAB, ABB, B, BA, BB, BAA, BBA, BAB, BBB
	A = p[xi + 1] + yi
	AA = p[A + 1] + zi
	AB = p[A + 1 + 1] + zi
	AAA = p[AA + 1]
	ABA = p[AB + 1]
	AAB = p[AA + 1 + 1]
	ABB = p[AB + 1 + 1]

	B = p[xi + 1 + 1] + yi
	BA = p[B + 1] + zi
	BB = p[B + 1 + 1] + zi
	BAA = p[BA + 1]
	BBA = p[BB + 1]
	BAB = p[BA + 1 + 1]
	BBB = p[BB + 1 + 1]

	return perlin_lerp(
		w,
		perlin_lerp(
			v,
			perlin_lerp(u, perlin_grad(AAA, x, y, z), perlin_grad(BAA, x - 1, y, z)),
			perlin_lerp(u, perlin_grad(ABA, x, y - 1, z), perlin_grad(BBA, x - 1, y - 1, z))
		),
		perlin_lerp(
			v,
			perlin_lerp(u, perlin_grad(AAB, x, y, z - 1), perlin_grad(BAB, x - 1, y, z - 1)),
			perlin_lerp(u, perlin_grad(ABB, x, y - 1, z - 1), perlin_grad(BBB, x - 1, y - 1, z - 1))
		)
	)
end
