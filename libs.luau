local libs = {}

if _G.DAL_globals then
	libs = require("./src/globals")
end

if _G.DAL_bit32 then
	libs.bit32 = require("./src/bit32")
end

if _G.DAL_buffer then
	libs.buffer = require("./src/buffer")
end

if _G.DAL_debug then
	libs.debug = require("./src/debug")
end

if _G.DAL_math then
	libs.math = require("./src/math")
end

if _G.DAL_os then
	libs.os = require("./src/os")
end

if _G.DAL_string then
	libs.string = require("./src/string")
end

if _G.DAL_table then
	libs.table = require("./src/table")
end

return libs
