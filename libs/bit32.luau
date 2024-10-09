--!nocheck

if bit32 then
	return bit32
end

return require("./bit32_lua53") :: typeof(bit32)
