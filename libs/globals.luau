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
	local mt = getmetatable(value :: any)
	local customtype = customtypes[mt]
	if customtype then
		return customtype
	end
	return dal_type(value)
end

local function dal_rawget(t: {}, k: any): any
	if _G.__DAL_RUNTIME_TYPE_CHECKING__ then
		if dal_typeof(t) ~= "table" then
			error(`invalid argument #1 to 'rawget' (table expected, got {dal_typeof(t)})`)
		end
	end
	if proxies[t] then
		return t[k]
	end
	return rawget(t, k)
end

local function dal_rawset(t: {}, k: any, v: any): ()
	if _G.__DAL_RUNTIME_TYPE_CHECKING__ then
		if dal_typeof(t) ~= "table" then
			error(`invalid argument #1 to 'rawset' (table expected, got {dal_typeof(t)})`)
		end
	end
	if proxies[t] then
		t[k] = v
	else
		rawset(t, k, v)
	end
end

local function dal_next(t: {}, i)
	if _G.__DAL_RUNTIME_TYPE_CHECKING__ then
		if dal_typeof(t) ~= "table" then
			error(`invalid argument #1 to 'next' (table expected, got {dal_typeof(t)})`)
		end
	end
	return next(t, i)
end

local unpack = table.unpack

local dal_unpack: any
if _G.__DAL_RUNTIME_TYPE_CHECKING__ then
	dal_unpack = function(tbl: {}, f: number?, t: number?)
		if dal_typeof(tbl) ~= "table" then
			error(`invalid argument #1 to 'unpack' (table expected, got {dal_typeof(tbl)})`)
		end
		return unpack(tbl, f, t)
	end
else
	dal_unpack = unpack
end

local dal_pairs
if _G.__DAL_HASHED_PAIRS__ then
	dal_pairs = function(t: {})
		if _G.__DAL_RUNTIME_TYPE_CHECKING__ then
			if dal_typeof(t) ~= "table" then
				error(`invalid argument #1 to 'pairs' (table expected, got {dal_typeof(t)})`)
			end
		end
		local frozen = frozentables[t]
		if frozen then
			t = frozen[privatekey]
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
		if _G.__DAL_RUNTIME_TYPE_CHECKING__ then
			if dal_typeof(t) ~= "table" then
				error(`invalid argument #1 to 'pairs' (table expected, got {dal_typeof(t)})`)
			end
		end
		local frozen = frozentables[t]
		if frozen then
			t = frozen[privatekey]
		end
		return pairs(t) :: any
	end
end

local function dal_ipairs(t: {})
	if _G.__DAL_RUNTIME_TYPE_CHECKING__ then
		if dal_typeof(t) ~= "table" then
			error(`invalid argument #1 to 'ipairs' (table expected, got {dal_typeof(t)})`)
		end
	end
	local frozen = frozentables[t]
	if frozen then
		t = frozen[privatekey]
	end
	return ipairs(t)
end

local proxyMetatables = {}
local function dal_getmetatable(value): any
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

local function __DAL_INTERNAL_getmetatable(value)
	local iterMethod = lockedtables[value]
	if iterMethod then
		return {
			__iter = iterMethod,
		}
	end
	return dal_getmetatable(value)
end

local function dal_setmetatable(tbl: {}, mt: { [any]: any } | nil)
	if _G.__DAL_RUNTIME_TYPE_CHECKING__ then
		if dal_typeof(tbl) ~= "table" then
			error(`invalid argument #1 to 'setmetatable' (table expected, got {dal_typeof(tbl)})`)
		elseif dal_typeof(mt) ~= "table" and mt ~= nil then
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
	error(`attempt to index {typeof(self)} with '{k}'`)
end

function userdata.__newindex(self, k)
	error(`attempt to index {typeof(self)} with '{k}'`)
end

function userdata.__len(self)
	error(`attempt to get length of a {typeof(self)} value`)
end

function userdata.__call(self)
	error(`attempt to call a {typeof(self)} value`)
end

local function arithmeticError(metamethod, a, b)
	local aType = typeof(a)
	local bType = typeof(b)
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
	error(`attempt to compare {typeof(a)} < {typeof(b)}`)
end

function userdata.__le(a, b)
	error(`attempt to compare {typeof(a)} <= {typeof(b)}`)
end

function userdata.__concat(a, b)
	error(`attempt to concatenate {typeof(a)} with {typeof(b)}`)
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
	error(`attempt to iterate over a {typeof(self)} value`)
end

nativetypes[userdata] = "userdata"

local function dal_newproxy(mt: boolean?)
	if _G.__DAL_RUNTIME_TYPE_CHECKING__ then
		if mt and type(mt) ~= "boolean" then
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
		error(`invalid argument #1 to 'getfenv' (number expected, got {dal_typeof(fnOrIndex)})`)
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
		error(`invalid argument #1 to 'getfenv' (number expected, got {dal_typeof(fnOrIndex)})`)
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
	__DAL_INTERNAL_getmetatable = (__DAL_INTERNAL_getmetatable :: any) :: typeof(getmetatable),
	setmetatable = (dal_setmetatable :: any) :: typeof(setmetatable),
	newproxy = (dal_newproxy :: any) :: typeof(newproxy),
	gcinfo = (dal_gcinfo :: any) :: typeof(gcinfo),
	setfenv = (dal_setfenv :: any) :: typeof(setfenv),
	getfenv = (dal_getfenv :: any) :: typeof(getfenv),
	_VERSION = "Luau",
}
