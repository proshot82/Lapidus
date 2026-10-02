-- build/l9v/alt.lua файл.lua — альтернативные разметки видимого проигрыша для g7 (правила §7, которых в файле нет).
-- Каждое правило проверяется на «не помечает живых». Печать — только метрики.
--   W  «резьба в стену»: закреплённая подвижная деталь, у которой резьба смотрит в стену или в глухой бок закреплённого,
--      — вечная протечка, как только сеть намокнет («выход занят деталью, чья резьба явно никуда не ведёт», §7).
--   T  «линия унитаза перекрыта»: в клетке между гребёнкой и трубой унитаза закреплена деталь без резьбы к трубе унитаза.
--   S  «не с той стороны»: свободная нужная деталь на карнизе (ряд 5, x ≤ 6) или на клетке (6,4) над деталью в (6,5),
--      а Лапидус целиком справа от неё — обойти деталь в однорядном карнизе нельзя (сокобан).
--   D  «карточка: сухая хватает»: подвижная деталь (кроме ниппеля) закреплена на сухой гребёнке не на своём финальном месте.
--      Это мерка «знатока карточки», а не новичка — для оценки трактовки, где ошибка «собрать всухую» видна сразу.
local L = dofile("build/l9v/lib.lua")
local S = L.load(arg[1])
local R, V = L.R, L.V
local lvl = S.lvl
local W = lvl.W
local function idx(x, y) return (y - 1) * W + x end
local tags = {}
for q, p in ipairs(lvl.pieces) do if p.tag then tags[p.tag] = q end end
local win = S.VL.win
local function occ(s) local t = {} for q = 1, #s.pos do if s.pos[q] ~= 0 then t[s.pos[q]] = q end end return t end
local rules = {}
rules.W = function(s)
  local o = occ(s)
  for q, p in ipairs(lvl.pieces) do if p.movable and s.pos[q] ~= 0 and s.fixed[q] then
    for d = 1, 4 do if p.ports[d] then
      local t = lvl.nb[s.pos[q]][d]
      if t == 0 or lvl.cell[t] == R.WALL then return true end
      local r = o[t]
      if r and s.fixed[r] and not R.match(p.ports[d], lvl.pieces[r].ports[R.OPP[d]]) then return true end
    end end
  end end
  return false
end
rules.T = function(s)
  local c = idx(9, 7)
  local o = occ(s)
  local q = o[c]
  if q and s.fixed[q] then local p = lvl.pieces[q]; if p.ports[R.RIGHT] ~= "V" then return true end end
  return false
end
rules.S = function(s)
  local o = occ(s)
  local bodyMinX = 99
  for _, c in ipairs(s.body) do local x, y = R.xy(lvl, c)
    -- левая область: карниз x ≤ 5, левая шахта, нижняя комната
    if (y == 5 and x <= 5) or (x == 2 and (y == 6 or y == 7)) or y == 8 then bodyMinX = math.min(bodyMinX, (y == 5) and x or 0) end
  end
  for _, tg in ipairs({ "tee", "plug" }) do local q = tags[tg]
    if q and s.pos[q] ~= 0 and not s.fixed[q] then
      local x, y = R.xy(lvl, s.pos[q])
      local onLedge = (y == 5 and x <= 6)
      local stacked = (x == 6 and y == 4 and o[idx(6, 5)] and not s.fixed[o[idx(6, 5)]])
      local px = stacked and 6 or x
      if (onLedge or stacked) and not (bodyMinX < px) then return true end
    end
  end
  return false
end
rules.D = function(s)
  if S:wet(s) then return false end
  for q, p in ipairs(lvl.pieces) do if p.movable and p.tag ~= "nip" and s.pos[q] ~= 0 and s.fixed[q]
    and not (win.fixed[q] and win.pos[q] == s.pos[q]) then return true end end
  return false
end
-- проверка правил: не помечают живых; сколько скрытых (новичок) они помечают
local marks = {}
for name, f in pairs(rules) do
  local m, liveHit, hidHit = {}, 0, 0
  for i = 1, S.n do if S.flag[i] ~= 2 then
    if f(S:st(i)) then m[i] = true; if S:live(i) then liveHit = liveHit + 1 elseif S:hid(i) then hidHit = hidHit + 1 end end
  end end
  marks[name] = m
  print(string.format("правило %s: помечает живых %d (должно быть 0), скрытых по линейке %d", name, liveHit, hidHit))
end
local function combo(list)
  local arr = {}
  for i = 1, S.n do if S.flag[i] ~= 2 then
    local v = S.VL.newbie[i]
    if not v then for _, nm in ipairs(list) do if marks[nm][i] then v = true break end end end
    -- правило уровня не может помечать живых: если вдруг пометило — не берём
    if v and S:live(i) and not S.VL.newbie[i] then v = false end
    arr[i] = v
  end end
  return arr
end
local sp = S:onShortest()
local function doors(arr)
  local ph = {}
  for i = 1, S.n do if sp[i] and S.flag[i] == 0 then
    for e = S.ES[i-1], S.ES[i]-1 do local j = S.E[e]
      if S:hid(j, arr) then ph[S.G.depth[i]] = (ph[S.G.depth[i]] or 0) + 1 end end end end
  local t = {}
  for d = 0, S:opt() - 1 do if ph[d] then t[#t+1] = d .. ":" .. ph[d] end end
  return table.concat(t, " ")
end
local sets = { {}, { "W" }, { "T" }, { "S" }, { "D" }, { "W", "T" }, { "D", "T" }, { "T", "S" }, { "W", "S" }, { "D", "T", "S" }, { "W", "T", "S" }, { "W", "T", "S", "D" } }
print("разметка | скрытых % (от скрытых+живых) | умная обезьяна % | глубина у пути | двери с ЛЮБЫХ кратчайших (шаг:число)")
for _, set in ipairs(sets) do
  local arr = combo(set)
  local m = V.measure(S.G, S.good, arr)
  print(string.format("  линейка%-12s %5.1f %%  обез %.3f  гл %2d  двери [%s]", (#set > 0 and ("+" .. table.concat(set, "+")) or ""), m.hiddenPct, m.smart, m.maxDeep, doors(arr)))
end
local m = V.measure(S.G, S.good, S.VL.expert)
print(string.format("  знаток           %5.1f %%  обез %.3f  гл %2d  двери [%s]", m.hiddenPct, m.smart, m.maxDeep, doors(S.VL.expert)))
S:free()
