
[한국어](README_kr.md) 👈
# English

## dal-polyfill
Polyfill libraries for dal used transpiling luau to lua (especially Lua 5.3)

### Implementations
#### Globals
- [x] `typeof`
- [x] `unpack`
- [x] `pairsWithHash` (uses `djb2` hashing internally which isn't equivalent to Luau's)
- [x] `newproxy`
- [x] `gcinfo`
- More details [here](libs/globals.luau)

#### Libraries
- [x] `buffer`
- [x] `math`
- [x] `os` (sandboxed)
- [x] `string`
- [x] `table`
- [x] `debug`
- [x] `bit32`
