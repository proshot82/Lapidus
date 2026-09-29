-- live.lua файл.lua "подстрока подписи" [N] — живые состояния с подписью (отладка замысла; вывод инструмента) и
-- сколько ходов до победы из них.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local pat, N = arg[2], tonumber(arg[3] or 3)
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local P = lvl.pieces
local src; for q, p in ipairs(P) do if p.source then src = q end end
local sx, sy = R.xy(lvl, P[src].start)
-- расстояние до победы (обратный BFS)
local n = G.n
local E, ES = G.edges.p, G.eStart.p
local rev = {}
for i = 1, n do for e = ES[i - 1], ES[i] - 1 do local j = E[e]; local t = rev[j]; if not t then t = {}; rev[j] = t end; t[#t + 1] = i end end
local dw, q, h = {}, {}, 1
for i = 1, n do if G.flag[i] == 1 then dw[i] = 0; q[#q + 1] = i end end
while h <= #q do local u = q[h]; h = h + 1; for _, p in ipairs(rev[u] or {}) do if dw[p] == nil and G.flag[p] ~= 2 then dw[p] = dw[u] + 1; q[#q + 1] = p end end end
local function where(st, qq)
  local c = st.pos[qq]; local x, y = R.xy(lvl, c)
  if x == sx then return (st.fixed[qq] and "F" or "столб") .. y end
  return ((x < sx) and "Л" or "П") .. (st.fixed[qq] and "F" or "") .. y
end
local shown = 0
for i = 1, n do
  if shown >= N then break end
  if G.flag[i] == 0 and good[i] == 1 then
    local st = R.decode(lvl, G.keys[i])
    local t = {}
    for qq, p in ipairs(P) do if p.movable then t[#t + 1] = p.tag .. ":" .. where(st, qq) end end
    local s = table.concat(t, " ")
    if s:find(pat, 1, true) then
      shown = shown + 1
      local rows = {}
      for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or "." end end
      for qq, p in ipairs(P) do if st.pos[qq] ~= 0 then local x, y = R.xy(lvl, st.pos[qq]); local ch = p.tag and p.tag:sub(1,1) or (p.source and "S" or "F"); if p.movable and st.fixed[qq] then ch = ch:upper() end; rows[y][x] = ch end end
      for j, c in ipairs(st.body) do local x, y = R.xy(lvl, c); rows[y][x] = (j == #st.body) and "H" or ((j == 1) and "f" or "o") end
      for y = 1, lvl.H do print(table.concat(rows[y])) end
      print("до победы " .. tostring(dw[i]) .. " ходов; " .. s)
    end
  end
end
SV.freeGraph(G); require("ffi").C.free(good)
