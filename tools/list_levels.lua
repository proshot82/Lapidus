-- Список уровней для tools/probe.lua: LEVELS="1 4" luajit tools/probe.lua tools/list_levels.lua 400000
local t = {}
for id in (os.getenv("LEVELS") or "1 2 3 4"):gmatch("%d+") do
  local n = tonumber(id)
  local d = dofile(string.format("levels/%02d.lua", n))
  d.tagname = string.format("levels/%02d", n)
  t[#t + 1] = d
end
return t
