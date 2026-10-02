-- diag.lua файл.lua [режим why] — какие правила разметки срабатывают на живых/скрытых/видимых (для отладки разметки).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local why = assert(def.visModes and def.visModes.why, "нужен visModes.why")
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local cnt = { live = {}, dead = {} }
local ex = {}
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i])
    local w = why(lvl, st) or "-"
    local t = good[i] == 1 and cnt.live or cnt.dead
    t[w] = (t[w] or 0) + 1
    if good[i] == 1 and w ~= "-" and not ex[w] then ex[w] = i end
  end
end
for _, k in ipairs({ "live", "dead" }) do
  local s = {}
  for w, n in pairs(cnt[k]) do s[#s + 1] = w .. "=" .. n end
  table.sort(s)
  print(k .. ": " .. table.concat(s, " "))
end
for w, i in pairs(ex) do print("пример живого с правилом " .. w .. ": состояние #" .. i) end
SV.freeGraph(G); require("ffi").C.free(good)
