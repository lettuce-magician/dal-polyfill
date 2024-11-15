local typeof = require("./globals").typeof
local isNumber = require("./isNumber")

--[=[
	Expects a number argument that cannot be a `nil`.

	Manually error handling is recommended for optional types for a better performance.

    ## Manually error handling for optional types example
	```lua
	if param ~= nil and not isNumber(param) then
		error(`invalid argument #4 to 'sans' (number expected, got {typeof(param)})`)
	end
	```
]=]
return function(value: number, index: number, funcName: string): never
	if value ~= nil then
		if not isNumber(value) then
			return error(`invalid argument #{index} to '{funcName}' (number expected, got {typeof(value)})`, 2)
		end
	end
	return error(`missing argument #{index} to '{funcName}' (number expected)`, 2)
end
