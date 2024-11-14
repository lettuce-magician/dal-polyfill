local utils = {}

local luau = require("@lune/luau")
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local base64 = require("../lune_packages/base64")

function utils.encodeBase64(b: buffer): buffer
    return base64.encode(b)
end

function utils.executePolyfill(code: string)
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

function utils.execute(code: string): (any, any)
	local luauResult = luau.load(code, {
		debugName = "luau execution"
	})()
	local polyfillResult = utils.executePolyfill(code)

	return luauResult, polyfillResult
end

return utils
