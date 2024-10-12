local typeof = require("./globals").typeof

local function clear(t: {})
	for i in pairs(t) do
		t[i] = nil
	end
end

-- selene: allow(manual_table_clone)
local function clone(t: {})
	local new = {}
	for i, v in pairs(t) do
		new[i] = v
	end
	return new
end

local function create(count: number, value: any)
	local new = {}
	if value then
		for i = 1, count do
			new[i] = value
		end
	end
	return new
end

local function find(t: {}, value: any): number?
	for i, v in ipairs(t) do
		if v == value then
			return i
		end
	end
	return nil
end

local function foreach(t: {}, fn: (any, any) -> ())
	for i, v in pairs(t) do
		fn(i, v)
	end
end

local function foreachi(t: {}, fn: (number, any) -> ())
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
end

local function isfrozen(t: {}): boolean
	return frozentables[t] ~= nil
end

local unpack = table.unpack
local pack = table.pack

local function getn(t: {}): number
	return pack(unpack(t)).n
end

local function maxn(t: {}): number
	local max = 0
	for k, v in pairs(t) do
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
