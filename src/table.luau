local typeof = require("./globals").typeof
local lockedtables = require("./lockedtables")
local isnumber = require("./isnumber")

local function clear(t: {})
	if _G.DAL_runtime_type_checking then
		if typeof(t) ~= "table" then
			error(`invalid argument #1 to 'clear' (table expected, got {typeof(t)})`)
		end
	end
	for i in pairs(t) do
		t[i] = nil
	end
end

local clone: any
if _G.DAL_allow_debug_library_usage then
	local getmt = (debug :: any).getmetatable
	clone = function(t: {})
		if _G.DAL_runtime_type_checking then
			if typeof(t) ~= "table" then
				error(`invalid argument #1 to 'clone' (table expected, got {typeof(t)})`)
			end
		end
		local mt = getmt(t)
		if mt.__metatable then
			error("invalid argument #1 to 'clone' (table has a protected metatable)")
		end
		-- selene: allow(manual_table_clone)
		local new = {}
		for i, v in pairs(t) do
			new[i] = v
		end
		setmetatable(new, mt)
		return new
	end
else
	clone = function(t)
		if _G.DAL_runtime_type_checking then
			if typeof(t) ~= "table" then
				error(`invalid argument #1 to 'clone' (table expected, got {typeof(t)})`)
			end
		end
		if lockedtables[t] == false then
			error("invalid argument #1 to 'clone' (table has a protected metatable)")
		end
		-- selene: allow(manual_table_clone)
		local new = {}
		for i, v in pairs(t) do
			new[i] = v
		end
		setmetatable(new, getmetatable(t))
		return new
	end
end

local function create<V>(count: number, value: V?): {V}
	if _G.DAL_runtime_type_checking then
		if not isnumber(count) then
			error(`invalid argument #1 to 'create' (number expected, got {typeof(count)})`)
		end
	end
	local new = {}
	if value then
		for i = 1, count do
			new[i] = value
		end
	end
	return new
end

local function find(t: {}, value: any): number?
	if _G.DAL_runtime_type_checking then
		if typeof(t) ~= "table" then
			error(`invalid argument #1 to 'find' (table expected, got {typeof(t)})`)
		elseif value == nil then
			error("missing argument #2")
		end
	end
	for i, v in ipairs(t) do
		if v == value then
			return i
		end
	end
	return nil
end

local function foreach(t: {}, fn: (any, any) -> ()): ()
	if _G.DAL_runtime_type_checking then
		if typeof(t) ~= "table" then
			error(`invalid argument #1 to 'foreach' (table expected, got {typeof(t)})`)
		elseif type(fn) ~= "function" then
			error(`invalid argument #2 to 'foreach' (function expected, got {typeof(fn)})`)
		end
	end
	for i, v in pairs(t) do
		fn(i, v)
	end
end

local function foreachi(t: {}, fn: (number, any) -> ()): ()
	if _G.DAL_runtime_type_checking then
		if typeof(t) ~= "table" then
			error(`invalid argument #1 to 'foreachi' (table expected, got {typeof(t)})`)
		elseif type(fn) ~= "function" then
			error(`invalid argument #2 to 'foreachi' (function expected, got {typeof(fn)})`)
		end
	end
	for i, v in pairs(t) do
		if type(i) == "number" then
			fn(i, v)
		end
	end
end

local frozentables = require("./frozentables")
-- local iteratables = require("./iteratables")
local privatekey = require("./privatekey")

local FrozenTable = {}

function FrozenTable.__index(self, k)
	return self[privatekey][k]
end

function FrozenTable.__newindex()
	error("attempt to modify a readonly table", 2)
end

function FrozenTable.__tostring(self): string
	return tostring(self[privatekey])
end

function FrozenTable.__len(self): number
	return #self[privatekey]
end

local function freeze(t: typeof(setmetatable({} :: {}, {} :: {})))
	if _G.DAL_runtime_type_checking then
		if typeof(t) ~= "table" then
			error(`invalid argument #1 to 'freeze' (table expected, got {typeof(t)})`)
		end
	end
	if _G.DAL_emulate_frozen_table then
		local mt = getmetatable(t)
		local freezeMt
		if mt then
			freezeMt = clone(FrozenTable)
			for method, f in mt do
				if method ~= "__newindex" then
					freezeMt[method] = f
				end
			end
		else
			freezeMt = FrozenTable
		end
		local frozen = setmetatable({
			[privatekey] = t,
		}, freezeMt)

		-- frozentables[frozen] = {
		-- 	[1] = mt,
		-- 	[2] = t :: any,
		-- }
		frozentables[frozen] = mt or false
		-- iteratables[frozen] = t

		return frozen
	else
		frozentables[t] = false
		return t
	end
end

local function isfrozen(t: {}): boolean
	if _G.DAL_runtime_type_checking then
		if typeof(t) ~= "table" then
			error(`invalid argument #1 to 'isfrozen' (table expected, got {typeof(t)})`)
		end
	end
	return frozentables[t] ~= nil
end

local unpack = table.unpack
local pack = table.pack

local function getn(t: {}): number
	if _G.DAL_runtime_type_checking then
		if typeof(t) ~= "table" then
			error(`invalid argument #1 to 'getn' (table expected, got {typeof(t)})`)
		end
	end
	return pack(unpack(t)).n
end

local function maxn(t: {}): number
	if _G.DAL_runtime_type_checking then
		if typeof(t) ~= "table" then
			error(`invalid argument #1 to 'maxn' (table expected, got {typeof(t)})`)
		end
	end
	local max = 0
	for k, _ in pairs(t) do
		if type(k) == "number" and k > max then
			max = k
		end
	end
	return max
end

return (
	{
		clear = clear,
		clone = clone,
		create = create,
		find = find,
		foreach = foreach,
		foreachi = foreachi,
		freeze = (freeze :: any) :: typeof(table.freeze),
		getn = getn,
		isfrozen = isfrozen,
		maxn = maxn,
		concat = table.concat,
		insert = table.insert,
		move = table.move,
		pack = table.pack,
		remove = table.remove,
		sort = table.sort,
		unpack = table.unpack,
	} :: any
) :: typeof(table)
