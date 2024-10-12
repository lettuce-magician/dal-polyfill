local typeof = require("./typeof")
local nativetypes = require("./nativetypes")
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

nativetypes[userdata] = "userdata"

return userdata
