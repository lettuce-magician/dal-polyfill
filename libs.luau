local libs = {}

if _G.DAL_globals then
	libs = require("./libs/globals")
end

if _G.DAL_bit32 then
	libs.bit32 = require("./libs/bit32")
end

if _G.DAL_buffer then
	libs.buffer = require("./libs/buffer")
end

if _G.DAL_debug then
	libs.debug = require("./libs/debug")
end

if _G.DAL_math then
	libs.math = require("./libs/math")
end

if _G.DAL_os then
	libs.os = require("./libs/os")
end

if _G.DAL_string then
	libs.string = require("./libs/string")
end

if _G.DAL_table then
	libs.table = require("./libs/table")
end

return libs
