return function(value: any): boolean
    local t = type(value)
    return t == "string" or t == "number" -- numbers can be casted to string
end
