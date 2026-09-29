-- build/l2c/claims.lua файл.lua ROOM_X ROOM_Y — проверка заявленного «ага» кв. 2 на графе (как build/l6/claims.lua).
-- Ошибка подсказки №1 «начать не тем концом» = упасть из комнаты старта к шахте ногами вперёд.
-- Печатает: (1) судьбу каждого первого хода; (2) перепись состояний «ниже комнаты, не на крючьях» по тому, какой конец
-- впереди (ближе к шахте): живые / скрытые / видимые; (3) все ли падения из комнаты ногами вперёд ведут в скрытый тупик.
-- Кадров и порядка ходов не печатает.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local RX, RY = tonumber(arg[2] or 7), tonumber(arg[3] or 3)
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local W = lvl.W
local function xy(c) return (c - 1) % W + 1, math.floor((c - 1) / W) + 1 end
local function cls(i)
  if G.flag[i] == 2 then return "смыло" end
  if G.flag[i] == 1 then return "победа" end
  if good[i] == 1 then return "живое" end
  return VL.newbie[i] and "видимый тупик" or "СКРЫТЫЙ тупик"
end
local st = {}
for i = 1, G.n do st[i] = R.decode(lvl, G.keys[i]) end
local function inRoom(s) for _, c in ipairs(s.body) do local x, y = xy(c); if x >= RX and y <= RY then return true end end return false end
local function below(s) for _, c in ipairs(s.body) do local _, y = xy(c); if y <= RY then return false end end return true end
local function hooked(s) local o = R.occupancy(s); return R.endScrew(lvl, s, o, "head") or R.endScrew(lvl, s, o, "heel") end
-- (1) первые ходы
local t = {}
for e = G.eStart.p[0], G.eStart.p[1] - 1 do t[#t + 1] = cls(G.edges.p[e]) end
table.sort(t)
print("старт: ходов " .. #t .. " → " .. table.concat(t, ", "))
-- (2) перепись ниже комнаты
local cnt = {}
local function add(k, c) cnt[k] = cnt[k] or {}; cnt[k][c] = (cnt[k][c] or 0) + 1 end
for i = 1, G.n do
  local s = st[i]
  if G.flag[i] ~= 2 and not s.dead and below(s) and not hooked(s) then
    local hx, hy = xy(s.body[#s.body]); local fx, fy = xy(s.body[1])
    local headLead = (hx < fx) or (hx == fx and hy > fy)
    add(headLead and "голова впереди (к шахте)" or "ноги впереди (к шахте)", cls(i))
  end
end
for k, v in pairs(cnt) do
  local parts = {}
  for c, n in pairs(v) do parts[#parts + 1] = c .. " " .. n end
  table.sort(parts)
  print(string.format("ниже комнаты, не на крюке, %s: %s", k, table.concat(parts, ", ")))
end
-- (3) все переходы «из комнаты — вниз целиком»: чем кончается падение ногами вперёд и головой вперёд
local drops = {}
for i = 1, G.n do
  if G.flag[i] == 0 and inRoom(st[i]) and good[i] == 1 then
    for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do
      local j = G.edges.p[e]
      if G.flag[j] ~= 2 and below(st[j]) then
        local s = st[j]
        local _, hy = xy(s.body[#s.body]); local _, fy = xy(s.body[1])
        local k = (hy > fy) and "головой вперёд" or "ногами вперёд"
        add("падение " .. k, cls(j))
      end
    end
  end
end
for _, k in ipairs({ "падение ногами вперёд", "падение головой вперёд" }) do
  local v = cnt[k] or {}
  local parts = {}
  for c, n in pairs(v) do parts[#parts + 1] = c .. " " .. n end
  table.sort(parts)
  print(string.format("%s (из живых состояний комнаты): %s", k, table.concat(parts, ", ")))
end
-- проверка разметки: живые не помечены видимыми
local bad = 0
for i = 1, G.n do if G.flag[i] ~= 2 and good[i] == 1 and VL.newbie[i] then bad = bad + 1 end end
print("живых, помеченных видимым проигрышем: " .. bad)
SV.freeGraph(G); require("ffi").C.free(good)
