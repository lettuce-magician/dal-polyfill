local unpack = table.unpack

return function(tbl: {}, f: number?, t: number?)
	return unpack(tbl, f, t)
end
