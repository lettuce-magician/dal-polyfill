-- if the value is table, it is locked table which has __iter
-- if the value is false, it is just locked talbe by __metatable (= protected metatable)
-- if any value is listed in this table, it has been locked via setmetatable anyways
return setmetatable({}, { __mode = "k" })
