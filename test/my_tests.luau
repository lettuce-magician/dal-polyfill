local frktest = require("@frktest/")
local test = frktest.test
local check = frktest.assert.check

local luau = require("@lune/luau")
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local base64 = require("../lune_packages/base64")

local function executePolyfill(code: string)
	local config: { libraries: { [string]: boolean } } = serde.decode("toml", fs.readFile("config.toml"))
	for k, v in config.libraries do
		_G["DAL_" .. k] = v
	end
	_G.DAL_test_bit32 = true
	local libs = require("../libs")
	return luau.load(code, {
		debugName = "polyfill execution",
		environment = libs,
		injectGlobals = true
	})()
end

local function execute(code: string): (any, any)
	local luauResult = luau.load(code, {
		debugName = "luau execution"
	})()
	local polyfillResult = executePolyfill(code)

	return luauResult, polyfillResult
end

return function()
	test.suite("polyfill::bit32", function()
		test.case("arshift", function()
			execute([[

			return bit32.arshift(2, 5)

			]])
		end)
	end)

	test.suite("polyfill::buffer", function()
		test.case("writing integers", function()
			local luauResult, polyfillResult = execute([[

			local offset = 0
			local b = buffer.create(14)

			-- unsigned
			buffer.writeu8(b, offset, 2^8-1)
			offset += 1

			buffer.writeu16(b, offset, 2^16-1)
			offset += 2

			buffer.writeu32(b, offset, 2^32-1)
			offset += 4

			-- signed
			buffer.writei8(b, offset, 2^7-1)
			offset += 1

			buffer.writei16(b, offset, 2^15-1)
			offset += 2

			buffer.writei32(b, offset, 2^31-1)
			offset += 4

			offset = 0
			print(buffer.readu8(b, offset))
			offset += 1

			print(buffer.readu16(b, offset))
			offset += 2

			print(buffer.readu32(b, offset))
			offset += 4

			print(buffer.readi8(b, offset))
			offset += 1

			print(buffer.readi16(b, offset))
			offset += 2

			print(buffer.readi32(b, offset))
			offset += 4

			return buffer.tostring(b)

			]])
			local luauResult = buffer.fromstring(luauResult)
			local polyfillResult = buffer.fromstring(polyfillResult)
			print(buffer.len(luauResult), buffer.len(polyfillResult))

			check.equal(buffer.tostring(base64.encode(luauResult)), buffer.tostring(base64.encode(polyfillResult)))
		end)
	end)
end
