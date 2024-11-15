local typeof = require("./globals").typeof

--- `expectNumber`, `expectString`, and `expectTable` are recommended for numbers, strings, and tables.
type BasicTypeNames = "function" | "boolean"

--[=[
	Expects an argument type that cannot be a `nil`.

	Manually error handling is recommended for optional types for a better performance.

	## Manually error handling for optional types example
	```lua
	if param ~= nil and not isNumber(param) then
		error(`invalid argument #4 to 'sans' (number expected, got {typeof(param)})`)
	end
	```

	Recommended to use `expectNumber`, `expectString`, and `expectTable` for `number`s, `string`s, and `table`s.
]=]
return function<T>(value: T, typeName: BasicTypeNames, index: number, funcName: string): never
	if value ~= nil then
		if type(value) ~= typeName then
			return error(`invalid argument #{index} to '{funcName}' ({typeName} expected, got {typeof(value)})`, 2)
		end
	end
	return error(`missing argument #{index} to '{funcName}' ({typeName} expected)`, 2)
end
