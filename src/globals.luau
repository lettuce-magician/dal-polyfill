local customtypes = require("./customtypes")
local nativetypes = require("./nativetypes")
local weaktypes = require("./weaktypes")
local djb2 = require("./djb2")
local frozentables = require("./frozentables")
local privatekey = require("./privatekey")
local proxies = require("./proxies")
local lockedtables = require("./lockedtables")
local isnumber = require("./isnumber")

local function dal_type(value: any): string
	if _G.DAL_runtime_type_checking then
		if value == nil then
			error("missing argument #1")
		end
	end
	local customtype = weaktypes[value]
	if customtype then
		return customtype
	end
	local mt = getmetatable(value :: any)
	customtype = nativetypes[mt]
	if customtype then
		return customtype
	end
	return type(value)
end

local function dal_typeof(value: any): string
	if _G.DAL_runtime_type_checking then
		if value == nil then
			error("missing argument #1")
		end
	end
	local mt = getmetatable(value :: any)
	local customtype = customtypes[mt]
	if customtype then
		return customtype
	end
	return dal_type(value)
end

local function dal_rawget(t: {}, k: any): any
	if _G.DAL_runtime_type_checking then
		if dal_typeof(t) ~= "table" then
			error(`invalid argument #1 to 'rawget' (table expected, got {dal_typeof(t)})`)
		elseif k == nil then
			error("missing argument #2")
		end
	end
	if proxies[t] then
		return t[k]
	end
	return rawget(t, k)
end

local function dal_rawset(t: {}, k: any, v: any): ()
	if _G.DAL_runtime_type_checking then
		if dal_typeof(t) ~= "table" then
			error(`invalid argument #1 to 'rawset' (table expected, got {dal_typeof(t)})`)
		elseif k == nil then
			error("missing argument #2")
		elseif v == nil then
			error("missing argument #3")
		end
	end
	if proxies[t] then
		t[k] = v
	else
		rawset(t, k, v)
	end
end

local function dal_next(t: {}, i)
	if _G.DAL_runtime_type_checking then
		if dal_typeof(t) ~= "table" then
			error(`invalid argument #1 to 'next' (table expected, got {dal_typeof(t)})`)
		end
	end
	return next(t, i)
end

local dal_unpack = table.unpack

local dal_pairs
if _G.DAL_hash_pairs then
	dal_pairs = function(t: {})
		if _G.DAL_runtime_type_checking then
			if dal_typeof(t) ~= "table" then
				error(`invalid argument #1 to 'pairs' (table expected, got {dal_typeof(t)})`)
			end
		end
		if _G.DAL_emulate_frozen_table then
			local frozen = frozentables[t]
			if frozen then
				t = frozen[privatekey]
			end
		end

		local keys = {}
		local hashmap = {}
		for key in pairs(t) do
			local hash
			if type(key) == "number" then
				hash = key
			else
				hash = djb2(tostring(key))
			end
			table.insert(keys, hash)
			hashmap[hash] = key
		end

		table.sort(keys, function(a, b)
			return a < b
		end)

		local i = 0
		return function(): any
			i = i + 1
			local hashkey = keys[i]
			if hashkey then
				local key = hashmap[hashkey]
				if key then
					return key, t[key]
				end
			end
			return
		end
	end
else
	dal_pairs = function(t: {})
		if _G.DAL_runtime_type_checking then
			if dal_typeof(t) ~= "table" then
				error(`invalid argument #1 to 'pairs' (table expected, got {dal_typeof(t)})`)
			end
		end
		if _G.DAL_emulate_frozen_table then
			local frozen = frozentables[t]
			if frozen then
				t = frozen[privatekey]
			end
		end
		return pairs(t) :: any
	end
end

local function dal_ipairs(t: {})
	if _G.DAL_runtime_type_checking then
		if dal_typeof(t) ~= "table" then
			error(`invalid argument #1 to 'ipairs' (table expected, got {dal_typeof(t)})`)
		end
	end
	if _G.DAL_emulate_frozen_table then
		local frozen = frozentables[t]
		if frozen then
			t = frozen[privatekey]
		end
	end
	return ipairs(t)
end

local proxyMetatables = {}
local dal_getmetatable
if _G.DAL_emulate_frozen_table and _G.DAL_emulate_newproxy then
	dal_getmetatable = function(value: any): any
		if _G.DAL_runtime_type_checking then
			if value == nil then
				error("missing argument #1")
			end
		end
		local frozen = frozentables[value]
		if frozen then
			return frozen[1]
		end
		local mt = proxies[value] or getmetatable(value)
		if nativetypes[mt] or proxyMetatables[value] then
			return nil
		end
		return mt
	end
elseif _G.DAL_emulate_frozen_table then
	dal_getmetatable = function(value: any): any
		if _G.DAL_runtime_type_checking then
			if value == nil then
				error("missing argument #1")
			end
		end
		local frozen = frozentables[value]
		if frozen then
			return frozen[1]
		end
		return getmetatable(value)
	end
elseif _G.DAL_emulate_newproxy then
	dal_getmetatable = function(value: any): any
		if _G.DAL_runtime_type_checking then
			if value == nil then
				error("missing argument #1")
			end
		end
		local mt = proxies[value] or getmetatable(value)
		if nativetypes[mt] or proxyMetatables[value] then
			return nil
		end
		return getmetatable(value)
	end
else
	dal_getmetatable = function(value: any): any
		if _G.DAL_runtime_type_checking then
			if value == nil then
				error("missing argument #1")
			end
		end
		local mt = getmetatable(value)
		if nativetypes[mt] then
			return nil
		end
		return mt
	end
end

local function __DAL_getmetatable_iter(value)
	if _G.DAL_runtime_type_checking then
		if value == nil then
			error("missing argument #1")
		end
	end
	local iterMethod = lockedtables[value]
	if iterMethod then
		return {
			__iter = iterMethod,
		}
	end
	return dal_getmetatable(value)
end

local function dal_setmetatable(tbl: {}, mt: { [any]: any } | nil)
	if _G.DAL_runtime_type_checking then
		if dal_typeof(tbl) ~= "table" then
			error(`invalid argument #1 to 'setmetatable' (table expected, got {dal_typeof(tbl)})`)
		elseif mt ~= nil and dal_typeof(mt) ~= "table" then
			error(`invalid argument #2 to 'setmetatable' (nil or table expected, got {dal_typeof(mt)})`)
		end
	end
	if mt and mt.__metatable then
		local iterMethod = mt.__iter
		if iterMethod then
			lockedtables[tbl] = iterMethod
		else
			lockedtables[tbl] = false
		end
	end
	return setmetatable(tbl, mt)
end

local Proxy = {}

function Proxy.__newindex(self, k, v)
	self[privatekey][k] = v
	rawset(self, k, v)
end

local userdata = {}

function userdata.__index(self, k)
	error(`attempt to index {dal_typeof(self)} with '{k}'`)
end

function userdata.__newindex(self, k)
	error(`attempt to index {dal_typeof(self)} with '{k}'`)
end

function userdata.__len(self)
	error(`attempt to get length of a {dal_typeof(self)} value`)
end

function userdata.__call(self)
	error(`attempt to call a {dal_typeof(self)} value`)
end

local function arithmeticError(metamethod, a, b)
	local aType = dal_typeof(a)
	local bType = dal_typeof(b)
	if aType == bType then
		error(`attempt to perform arithmetic ({metamethod}) on {aType}`)
	else
		error(`attempt to perform arithmetic ({metamethod}) on {aType} and {bType}`)
	end
end

function userdata.__add(a, b)
	arithmeticError("add", a, b)
end

function userdata.__sub(a, b)
	arithmeticError("sub", a, b)
end

function userdata.__mul(a, b)
	arithmeticError("mul", a, b)
end

function userdata.__div(a, b)
	arithmeticError("div", a, b)
end

function userdata.__unm(a, b)
	arithmeticError("unm", a, b)
end

function userdata.__mod(a, b)
	arithmeticError("mod", a, b)
end

function userdata.__pow(a, b)
	arithmeticError("pow", a, b)
end

function userdata.__idiv(a, b)
	arithmeticError("idiv", a, b)
end

function userdata.__lt(a, b)
	error(`attempt to compare {dal_typeof(a)} < {dal_typeof(b)}`)
end

function userdata.__le(a, b)
	error(`attempt to compare {dal_typeof(a)} <= {dal_typeof(b)}`)
end

function userdata.__concat(a, b)
	error(`attempt to concatenate {dal_typeof(a)} with {dal_typeof(b)}`)
end

function userdata.__tostring(self)
	local mt = getmetatable(self)
	setmetatable(self :: any, nil)
	local display = "userdata: " .. tostring(self):sub(8)
	setmetatable(self :: any, mt)
	return display
	-- setmetatable(self :: any, nil)
	-- local display = "userdata: " .. tostring(self):sub(8)
	-- setmetatable(self :: any, userdata)
	-- return display
end

function userdata.__iter(self)
	error(`attempt to iterate over a {dal_typeof(self)} value`)
end

nativetypes[userdata] = "userdata"

local dal_newproxy
if _G.DAL_emulate_newproxy then
	dal_newproxy = function(mt: boolean?)
		if _G.DAL_runtime_type_checking then
			if mt ~= nil and type(mt) ~= "boolean" then
				error(`invalid argument #1 to 'newproxy' (nil or boolean expected, got {dal_typeof(mt)})`)
			end
		end
		local newud = {}
		if mt then
			-- selene: allow(manual_table_clone)
			local proxyMt = {}
			for i, v in pairs(userdata) do
				proxyMt[i] = v
			end
			setmetatable(newud, proxyMt)
			local p = {
				__newindex = function(self, k, v)
					proxyMt[k] = v
					rawset(self, k, v)
				end,
			}
			local pt = setmetatable({}, p)
			proxies[newud] = pt
			proxyMetatables[pt] = p
			weaktypes[newud] = "userdata"
		else
			setmetatable(newud, userdata)
		end
		return newud
	end
else
	dal_newproxy = function(mt: boolean?)
		if _G.DAL_runtime_type_checking then
			if mt ~= nil and type(mt) ~= "boolean" then
				error(`invalid argument #1 to 'newproxy' (nil or boolean expected, got {dal_typeof(mt)})`)
			end
		end
		local newud = {}
		if mt then
			setmetatable(newud, {})
			weaktypes[newud] = "userdata"
		else
			setmetatable(newud, userdata)
		end
		return newud
	end
end

local function dal_gcinfo(): number
	return collectgarbage("count")
end

local function dal_setfenv(fnOrIndex: () -> () | number, env)
	fnOrIndex = fnOrIndex or 1
	if isnumber(fnOrIndex) then
		local info = (debug :: any).getinfo(fnOrIndex) :: {
			func: () -> (),
			what: string,
		}
		if info.what == "C" then
			error("invalid argument #1 to 'getfenv' (invalid level)")
		end
		fnOrIndex = info.func
	elseif type(fnOrIndex) ~= "function" then
		error(`invalid argument #1 to 'setfenv' (function expected, got {dal_typeof(fnOrIndex)})`)
	end
	local i = 1
	while true do
		local name = (debug :: any).getupvalue(fnOrIndex, i)
		if name == "_ENV" then
			(debug :: any).upvaluejoin(fnOrIndex, i, function()
				return env
			end, 1)
			break
		elseif not name then
			break
		end
		i = i + 1
	end
	return fnOrIndex
end

local function dal_getfenv(fnOrIndex: (() -> () | number)?)
	fnOrIndex = fnOrIndex or 1
	if isnumber(fnOrIndex) then
		local info = (debug :: any).getinfo(fnOrIndex) :: {
			func: () -> (),
			what: string,
		}
		if info.what == "C" then
			error("invalid argument #1 to 'getfenv' (invalid level)")
		end
		fnOrIndex = info.func
	elseif type(fnOrIndex) ~= "function" then
		error(`invalid argument #1 to 'getfenv' (function expected, got {dal_typeof(fnOrIndex)})`)
	end
	local i = 1
	while true do
		local name, val = (debug :: any).getupvalue(fnOrIndex, i)
		if name == "_ENV" then
			return val
		elseif not name then
			break
		end
		i = i + 1
	end
	return
end

return {
	type = (dal_type :: any) :: typeof(type),
	typeof = (dal_typeof :: any) :: typeof(typeof),
	rawget = (dal_rawget :: any) :: typeof(rawget),
	rawset = (dal_rawset :: any) :: typeof(rawset),
	next = (dal_next :: any) :: typeof(next),
	unpack = (dal_unpack :: any) :: typeof(unpack),
	pairs = (dal_pairs :: any) :: typeof(pairs),
	ipairs = (dal_ipairs :: any) :: typeof(ipairs),
	getmetatable = (dal_getmetatable :: any) :: typeof(getmetatable),
	__DAL_getmetatable_iter = (__DAL_getmetatable_iter :: any) :: typeof(getmetatable),
	setmetatable = (dal_setmetatable :: any) :: typeof(setmetatable),
	newproxy = (dal_newproxy :: any) :: typeof(newproxy),
	gcinfo = (dal_gcinfo :: any) :: typeof(gcinfo),
	setfenv = (dal_setfenv :: any) :: typeof(setfenv),
	getfenv = (dal_getfenv :: any) :: typeof(getfenv),
	_VERSION = "Luau",
}
