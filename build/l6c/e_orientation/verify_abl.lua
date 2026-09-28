-- verify_abl.lua — проверка абляций РОЛИ для r9: размер графа под фильтром, решаемость,
-- сколько состояний кратчайшего пути фильтр запрещает, и контрольные фильтры (должны оставаться решаемыми).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local A = dofile("build/l6c/e_orientation/abl_e.lua")
local def = dofile(arg[1])
local lvl = R.compile(def)
local nq, cq
for q, p in ipairs(lvl.pieces) do if p.tag == "nip" then nq = q elseif p.tag == "cpl" then cq = q end end
local W = lvl.W
-- контроль 1: муфта не переходит ниппель поверху (зеркало noOver)
local function cplOver(l, st, ns)
  local n, c = ns.pos[nq], ns.pos[cq]
  if n == 0 or c == 0 or ns.fixed[nq] or ns.fixed[cq] then return true end
  if (n - 1) % W == (c - 1) % W and c < n then return false end
  return true
end
-- контроль 2: ниппель не поднимается выше ряда 2 (не касается приёма)
local function nipNotTop(l, st, ns) local n = ns.pos[nq]; return n == 0 or n > 2 * W end
-- контроль 3: муфта не касается левой половины пола левее x=3
local function cplNotWall(l, st, ns) local c = ns.pos[cq]; return c == 0 or ns.fixed[cq] or (c - 1) % W + 1 >= 3 end
local G = SV.explore(lvl, 3000000)
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local filters = { { "пара не держит муфту над сливом (noBridge)", A.noBridge }, { "ниппель не переходит муфту поверху (noOver)", A.noOver },
  { "контроль: муфта не переходит ниппель поверху", cplOver }, { "контроль: Лапидус не кран (noCrane)", A.noCrane },
  { "контроль: муфта не левее x=3", cplNotWall } }
print("полный граф: состояний " .. G.n .. ", ходов " .. G.depth[G.firstWin])
for _, f in ipairs(filters) do
  local onPath = 0
  for _, s in ipairs(path) do local st = R.decode(lvl, G.keys[s]); if not f[2](lvl, st, st) then onPath = onPath + 1 end end
  local G2 = SV.explore(lvl, 3000000, f[2])
  print(string.format("%-48s состояний %6d, %s; запрещает состояний кратчайшего пути: %d",
    f[1], G2.n, G2.firstWin and ("РЕШАЕМ за " .. G2.depth[G2.firstWin]) or "нерешаем", onPath))
  SV.freeGraph(G2)
end
SV.freeGraph(G)
