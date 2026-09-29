-- abl.lua файл.lua — абляции роли и контроли для семейства «паром» (решаемо/нерешаемо, число ходов), без кадров.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local k = {}
for q, p in ipairs(lvl.pieces) do if p.tag then k[p.tag] = q end; if p.source then k.src = q end; if p.fixture then k.fix = q end end
local sx = R.xy(lvl, lvl.pieces[k.src].start)
local function inCol(c) return c ~= 0 and (R.xy(lvl, c)) == sx end
local function side(c) if c == 0 then return 0 end local x = R.xy(lvl, c); return (x < sx) and -1 or ((x > sx) and 1 or 0) end
local tests = {
  { "РОЛЬ: тройник, въехав в столб, его не покидает (нет парома)", function(l, st, ns)
      return not (inCol(st.pos[k.tee]) and not st.fixed[k.tee] and not inCol(ns.pos[k.tee])) end },
  { "РОЛЬ: заглушка не въезжает в столб раньше тройника", function(l, st, ns)
      return not (inCol(ns.pos[k.plug]) and not inCol(ns.pos[k.tee])) end },
  { "РОЛЬ: тройник не попадает правее столба", function(l, st, ns)
      return not (side(ns.pos[k.tee]) == 1 and not ns.fixed[k.tee]) end },
  { "РОЛЬ: струя не поднимает детали", function(l, st, ns)
      for q, p in ipairs(l.pieces) do if p.movable and ns.pos[q] ~= 0 and not ns.fixed[q] and inCol(ns.pos[q]) then return false end end
      return true end },
  { "контроль: Лапидус не поднимает стопку сам (тройник не закреплён раньше ниппеля)", function(l, st, ns)
      return not (ns.fixed[k.tee] and not ns.fixed[k.nip]) end },
  { "контроль: Лапидус не ползёт по столбу, пока нет ниппеля", function(l, st, ns)
      if ns.fixed[k.nip] then return true end
      for _, c in ipairs(ns.body) do if inCol(c) then local _, y = R.xy(l, c); local _, sy = R.xy(l, l.pieces[k.src].start); if y >= sy - l.R then return false end end end
      return true end },
  { "РОЛЬ-2: нет ни парома, ни лаза Лапидуса по столбу до ниппеля", function(l, st, ns)
      if inCol(st.pos[k.tee]) and not st.fixed[k.tee] and not inCol(ns.pos[k.tee]) then return false end
      if ns.fixed[k.nip] then return true end
      local _, sy = R.xy(l, l.pieces[k.src].start)
      for _, c in ipairs(ns.body) do if inCol(c) then local _, y = R.xy(l, c); if y >= sy - l.R then return false end end end
      return true end },
  { "контроль: заглушка не бывает левее столба", function(l, st, ns) return side(ns.pos[k.plug]) ~= -1 end },
  { "контроль: заглушка не бывает на полке и в жёлобе (ряд опоры и выше вне столба)", function(l, st, ns)
      local c = ns.pos[k.plug]; if c == 0 or inCol(c) then return true end
      local _, y = R.xy(l, c); local _, sy = R.xy(l, l.pieces[k.src].start); return y >= sy - 1 end },
  { "контроль: тройник не свинчивается с заглушкой вне столба", function(l, st, ns)
      return not (not ns.fixed[k.tee] and ns.asm[k.tee] == ns.asm[k.plug] and not inCol(ns.pos[k.tee])) end },
}
local function run(filter)
  local d2 = SV.deepcopy(def); d2.ablations = nil
  local l2 = R.compile(d2)
  local G2 = SV.explore(l2, 3000000, filter)
  local ok = G2 and G2.firstWin ~= nil
  local mv = ok and G2.depth[G2.firstWin] or nil
  local n = G2 and G2.n or -1
  SV.freeGraph(G2)
  return ok, mv, n
end
for _, t in ipairs(tests) do
  local ok, mv, n = run(t[2])
  print(string.format("%-80s %s (%s ходов, %d сост.)", t[1], ok and "РЕШАЕМ" or "нерешаем", tostring(mv), n))
end
