local typeof = require("./globals").typeof
local isString = require("./isString")

--[=[
	Expects a string argument that cannot be a `nil`.

	Manually error handling is recommended for optional types for a better performance.

    ## Manually error handling for optional types example
	```lua
	if param ~= nil and not isNumber(param) then
		error(`invalid argument #4 to 'sans' (number expected, got {typeof(param)})`)
	end
	```
]=]
return function(value: string, index: number, funcName: string): never
	if value ~= nil then
		if not isString(value) then
			return error(`invalid argument #{index} to '{funcName}' (string expected, got {typeof(value)})`, 2)
		end
	end
	return error(`missing argument #{index} to '{funcName}' (string expected)`, 2)
end
