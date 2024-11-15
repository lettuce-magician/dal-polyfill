local typeof = require("./globals").typeof

--[=[
    Recommended to type check the tables due to custom types such as `buffer` from dal polyfill.

	Expects a table/custom data type(ex. `buffer`, `Instance`) argument that cannot be a `nil`.

	Manually error handling is recommended for optional types for a better performance.

    ## Manually error handling for optional types example
	```lua
	if param ~= nil and not isNumber(param) then
		error(`invalid argument #4 to 'sans' (number expected, got {typeof(param)})`)
	end
	```
]=]
return function<T>(value: T, typeName: "table" | string, index: number, funcName: string): never
	if value ~= nil then
		if typeof(value) ~= typeName then
			return error(`invalid argument #{index} to '{funcName}' ({typeName} expected, got {typeof(value)})`, 2)
		end
	end
	return error(`missing argument #{index} to '{funcName}' ({typeName} expected)`, 2)
end
