-- claims.lua файл.lua — проверка ложных планов по предикатам (без решений): живые / скрытые / видимые.
-- Предикаты: ниппель в колонке; ниппель на полу перед муфтой (ближе к стояку); пара «муфта сзади»; муфта у колонки.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local Q = {}
for q, p in ipairs(lvl.pieces) do if p.tag then Q[p.tag] = q end if p.fixture then Q.fx = q end if p.source then Q.src = q end end
local W = lvl.W
local function xy(c) return (c - 1) % W + 1, math.floor((c - 1) / W) + 1 end
local sx, sy = xy(lvl.pieces[Q.src].start)
local toward = (sx > xy(lvl.pieces[Q.fx].start)) and 1 or -1 -- стояк правее колонки → +1
local P = {
  ["ниппель вкручен в колонку"] = function(st) local c = st.pos[Q.nip]; if c == 0 or not st.fixed[Q.nip] then return false end
    for q = 1, #st.pos do if st.fixed[q] and st.pos[q] ~= 0 and lvl.pieces[q].source then end end
    local fx = lvl.pieces[Q.fx].start; for d = 1, 4 do if lvl.nb[fx][d] == c then return true end end return false end,
  ["ниппель на полу ближе к стояку, чем свободная муфта"] = function(st)
    local n, c = st.pos[Q.nip], st.pos[Q.cpl]; if n == 0 or c == 0 or st.fixed[Q.nip] or st.fixed[Q.cpl] then return false end
    local nx, ny = xy(n); local cx, cy = xy(c); return ny == sy and cy == sy and (nx - cx) * toward > 0 end,
  ["пара свинчена ниппелем к стояку"] = function(st)
    local n, c = st.pos[Q.nip], st.pos[Q.cpl]; if n == 0 or c == 0 or st.fixed[Q.nip] then return false end
    if st.asm[Q.nip] ~= st.asm[Q.cpl] then return false end
    local nx = xy(n); local cx = xy(c); return (nx - cx) * toward > 0 end,
  ["пара свинчена муфтой к стояку (верная)"] = function(st)
    local n, c = st.pos[Q.nip], st.pos[Q.cpl]; if n == 0 or c == 0 or st.fixed[Q.nip] then return false end
    if st.asm[Q.nip] ~= st.asm[Q.cpl] then return false end
    local nx = xy(n); local cx = xy(c); return (nx - cx) * toward < 0 end,
}
local function lost(st)
  for q, p in ipairs(lvl.pieces) do if p.movable and st.pos[q] == 0 then return true end end
  return def.visibleLoss and def.visibleLoss(lvl, st) or false
end
local res, first = {}, {}
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i])
    for name, f in pairs(P) do
      if f(st) then
        local a = res[name] or { 0, 0, 0, 1e9 }; res[name] = a
        if good[i] == 1 then a[1] = a[1] + 1 elseif lost(st) then a[3] = a[3] + 1 else a[2] = a[2] + 1 end
        if G.depth[i] < a[4] then a[4] = G.depth[i] end
      end
    end
  end
end
for name, a in pairs(res) do print(string.format("%-52s живых %5d  скрытых %5d  видимых %5d  (достижимо с %d-го хода)", name, a[1], a[2], a[3], a[4])) end
SV.freeGraph(G); require("ffi").C.free(good)
