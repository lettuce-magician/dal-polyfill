return function(value: any): boolean
	if type(value) == "number" or tonumber(value) ~= nil then
		return true
	end
	return false
end
