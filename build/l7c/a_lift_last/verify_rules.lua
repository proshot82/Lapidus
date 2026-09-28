-- verify_rules.lua файл.lua вариант — скептик кв. 7 (28.09): держится ли уровень на тонкостях движка напора?
-- Грузит КОПИЮ core/rules.lua с правкой (движок не меняется), строит граф и печатает: решаем ли, за сколько ходов,
-- сколько выигрышных, и проходит ли в изменённых правилах то же кратчайшее решение, что в настоящих (без ходов).
-- Варианты:
--   base        — без правки (контроль);
--   order       — толчки внутри шага в обратном порядке (снизу вверх, справа налево);
--   lapchain    — Лапидус, которого несёт струя, толкает цепочку деталей перед собой («по обычным правилам цепочки»);
--   literal     — «резьба сильнее струи» буквально по §4: первой прикручивается только деталь в первой клетке
--                 струи (затыкает течь); остальная резьба — после толчков струй;
--   jetstop     — струя останавливается на первой подвижной детали (толкает её, но дальше не идёт);
--   nocapabove  — Лапидус не может вдавить деталь в первую клетку фонтана сверху («глушится только сбоку»);
--   nocolumn    — клетка над верхушкой столба не опора (стоит только то, что внутри столба);
--   ghost_<тег> — струя не толкает и не держит одну деталь (adp, elb, cpl): нужна ли ей роль фонтана.
package.path = "./?.lua;" .. package.path
local variant = arg[2] or "base"
local f = assert(io.open("core/rules.lua")); local src = f:read("*a"); f:close()
local function sub(a, b)
  local s, n = src:gsub(a, b)
  assert(n > 0, "патч не применился: " .. variant)
  src = s
end
local plain = function(s) return (s:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")) end
if variant == "order" then
  sub(plain("tsort(bodies, function(x, y) return x.top < y.top end)"), "tsort(bodies, function(x, y) return x.top > y.top end)")
elseif variant == "lapchain" then
  sub(plain([==[    if not bodyAt[t] and piece[t] then return false end
  end
  for i = 1, #b do b[i] = lvl.nb[b[i]][d] end
  return true]==]), [==[    if not bodyAt[t] and piece[t] then
      local r = piece[t]
      if st.fixed[r] then return false end
      toPush[#toPush + 1] = st.asm[r]
    end
  end
  local save = cloneState(st)
  for _, a in ipairs(toPush) do
    local pc, ba = occupancy(st)
    local still = false
    for i = 1, #b do local t = lvl.nb[b[i]][d]; local r = t ~= 0 and pc[t]; if r and not ba[t] and st.asm[r] == a and not st.fixed[r] then still = true end end
    if still and not pushAssemblies(lvl, st, pc, ba, a, d) then
      st.pos, st.asm, st.fixed = save.pos, save.asm, save.fixed
      return false
    end
  end
  for i = 1, #b do b[i] = lvl.nb[b[i]][d] end
  return true]==])
  sub(plain([==[local function shiftLapidus(lvl, st, piece, bodyAt, d)
  local b = st.body]==]), [==[local function shiftLapidus(lvl, st, piece, bodyAt, d)
  local b = st.body
  local toPush = {}]==])
elseif variant == "literal" then
  sub(plain([==[    local c1 = threads(lvl, st, piece)
    local c2, c3 = false, false
    local sup = nil
    if lvl.R > 0 then
      local w = R.water(lvl, st, piece)
      local jets, anchored = computeJets(lvl, st, piece, bodyAt, w)
      sup = jetSupport(lvl, jets)
      c2 = applyJets(lvl, st, jets, anchored)
      if c2 then wash(lvl, st) end
    end]==]), [==[    local c1 = false
    local c2, c3 = false, false
    local sup = nil
    if lvl.R > 0 then
      local w = R.water(lvl, st, piece)
      -- затыкание: деталь в первой клетке течи с подходящей резьбой прикручивается до толчка
      for _, L in ipairs(w.leaks) do
        if L.piece then
          local t = lvl.nb[L.cell][L.dir]
          local r = (t ~= 0) and piece[t] or nil
          if r and not st.fixed[r] and match(lvl.pieces[L.piece].ports[L.dir], lvl.pieces[r].ports[OPP[L.dir]]) then
            local a = st.asm[r]
            for k = 1, #st.pos do if st.pos[k] ~= 0 and not st.fixed[k] and st.asm[k] == a then st.fixed[k] = true end end
            c1 = true
          end
        end
      end
      piece, bodyAt = occupancy(st)
      w = R.water(lvl, st, piece)
      local jets, anchored = computeJets(lvl, st, piece, bodyAt, w)
      sup = jetSupport(lvl, jets)
      c2 = applyJets(lvl, st, jets, anchored)
      if c2 then wash(lvl, st) end
    end
    piece, bodyAt = occupancy(st)
    if threads(lvl, st, piece) then c1 = true end]==])
elseif variant == "jetstop" then
  sub(plain([==[      if anchored and bodyAt[t] then break end
      cells[#cells + 1] = t]==]), [==[      if anchored and bodyAt[t] then break end
      cells[#cells + 1] = t
      if r then break end]==])
elseif variant == "nocolumn" then
  sub(plain([==[      local top = lvl.nb[j.cells[#j.cells]][UP]
      if top ~= 0 then sup[top] = true end]==]), "")
elseif variant:match("^ghost_") then
  -- струя не толкает и не держит одну деталь (по тегу): проверка, нужна ли этой детали роль фонтана
  local tg = variant:sub(7)
  sub(plain("      if r and not fixed[r] then\n        local a = asm[r]"),
      "      if r and not fixed[r] and lvl.pieces[r].tag ~= '" .. tg .. "' then\n        local a = asm[r]")
  sub(plain("          local s = (sup ~= nil) and (sup[c] == true)"),
      "          local s = (sup ~= nil) and (sup[c] == true) and lvl.pieces[q].tag ~= '" .. tg .. "'")
elseif variant ~= "base" and variant ~= "nocapabove" then
  error("неизвестный вариант " .. variant)
end
local Rp = assert(load(src, "=rules_" .. variant))()
package.loaded["core.rules"] = Rp
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = Rp.compile(def)
local filter = nil
if variant == "nocapabove" then
  -- запрет: ход вниз, после которого деталь оказалась в клетке прямо над выходом стояка и прикрутилась
  local srcC
  for _, p in ipairs(lvl.pieces) do if p.source then srcC = p.start end end
  local first = lvl.nb[srcC][1]
  filter = function(lvl, st, ns)
    for q = 1, #ns.pos do
      if ns.pos[q] == first and ns.fixed[q] and not st.fixed[q] and st.pos[q] == lvl.nb[first][1] then return false end
    end
    return true
  end
end
local G = SV.explore(lvl, 3000000, filter)
local nwin = 0
for i = 1, G.n do if G.flag[i] == 1 then nwin = nwin + 1 end end
-- кратчайшее решение настоящего движка
package.loaded["core.rules"] = nil; package.loaded["solver.solve"] = nil
local R0 = require("core.rules")
local SV0 = require("solver.solve")
local lvl0 = R0.compile(def)
local G0 = SV0.explore(lvl0, 3000000)
local moves, x = {}, G0.firstWin
while x ~= 1 do table.insert(moves, 1, G0.pmove[x]); x = G0.parent[x] end
local s = Rp.newState(lvl)
local okReplay, diverge = true, nil
local s0 = R0.newState(lvl0)
for k, m in ipairs(moves) do
  local mm = Rp.MOVES[m]
  local ns = Rp.move(lvl, s, mm.which, mm.dir)
  local ns0 = R0.move(lvl0, s0, mm.which, mm.dir)
  if not ns or ns.dead then okReplay = false; diverge = diverge or k; break end
  if Rp.key(ns) ~= R0.key(ns0) and not diverge then diverge = k end
  s, s0 = ns, ns0
end
local winReplay = okReplay and Rp.isWin(lvl, s)
print(string.format("[%s] состояний %d, %s, выигрышных %d | кратчайшее решение настоящего движка: %s%s",
  variant, G.n, G.firstWin and ("решаем за " .. G.depth[G.firstWin]) or "НЕРЕШАЕМ", nwin,
  winReplay and "проходит" or "НЕ проходит",
  diverge and string.format(" (кадры расходятся с шага %d из %d)", diverge, #moves) or " (кадры совпадают)"))
