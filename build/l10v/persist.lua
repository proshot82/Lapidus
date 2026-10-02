-- build/l10v/persist.lua файл.lua — стойкость ошибок плана с кратчайших путей o34 (разметка файл+Y; для сравнения — файл):
-- от каждой двери (удаление 0) — по скрытым состояниям:
--   мин. ходов до видимого (любым способом — «самое быстрое вскрытие»);
--   мин. ходов до вехи ложного плана «ниппель закреплён у мойки» и «тройник закрыл колодец» (естественное продолжение:
--   игрок, считающий, что сторона унитаза готова, ведёт детали в колодец), и скрыто ли состояние перед вехой;
--   глубина скрытой области (максимум блуждания);
--   для сравнения — сколько ходов от той же точки до вехи «тройник закрыл колодец» по верному пути. Только метрики.
local L = dofile("build/l10v/lib.lua")
local S = L.load(arg[1])
local R = L.R
local lvl = S.lvl
local tags, sinkQ = {}, nil
for q, p in ipairs(lvl.pieces) do if p.tag then tags[p.tag] = q end; if p.what == "sink" then sinkQ = q end end
local toilet, srcC, c47 = R.idx(lvl, 10, 5), R.idx(lvl, 6, 7), R.idx(lvl, 4, 7)
local Y = {}
for i = 1, S.n do if S.flag[i] ~= 2 then local s = S:st(i)
  Y[i] = S.VL.newbie[i] or (not S:live(i) and s.pos[tags.tee] == srcC and s.fixed[tags.tee] and not R.water(lvl, s).wet[sinkQ]) end end
local function label(s)
  if s.fixed[tags.nip] and s.pos[tags.nip] == toilet then return "ниппель к унитазу" end
  if s.fixed[tags.adp] and s.pos[tags.adp] == toilet then return "переходник к унитазу" end
  if s.pos[tags.tee] == srcC and s.fixed[tags.tee] then return "тройник закрыл колодец" end
  return "тройник лежит в дыре на теле"
end
local teeClosed = function(s) return s.pos[tags.tee] == srcC and s.fixed[tags.tee] end
local nipSink = function(s) return s.pos[tags.nip] == c47 and s.fixed[tags.nip] end
local function bfs(j, pred, arr)
  -- по скрытым (arr) состояниям; веха может быть и видимой (момент правды)
  local s0 = S:st(j)
  if pred(s0) then return 0, not arr[j] end
  local d, q, h = { [j] = 0 }, { j }, 1
  while h <= #q do local u = q[h]; h = h + 1
    for e = S.ES[u-1], S.ES[u]-1 do local v = S.E[e]
      if S.flag[v] == 0 and not S:live(v) and d[v] == nil then
        d[v] = d[u] + 1
        if pred(S:st(v)) then return d[v], not arr[v] end
        if not arr[v] then q[#q+1] = v end end end end
  return nil
end
local dw, sp = S:distWin(), S:onShortest()
-- на верном пути: ходов от каждого шага до закрытия колодца
local path, x = {}, S.G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = S.G.parent[x] end
table.insert(path, 1, 1)
local closeStep
for k, id in ipairs(path) do if teeClosed(S:st(id)) then closeStep = k - 1 break end end
print(string.format("верный путь (check.lua): колодец закрывается на шаге %d из %d", closeStep, #path - 1))
print("дверь: шаг | класс | до видимого Y / файл | до «ниппель у мойки» (скрыто?) | до «тройник закрыл» (скрыто перед?) | глубина Y / файл | верным путём до закрытия")
for i in pairs(sp) do if S.flag[i] == 0 and S:live(i) then
  for e = S.ES[i-1], S.ES[i]-1 do local j = S.E[e]
    if S:hid(j) then
      local s = S:st(j)
      local rY, rF = S:reveal(j, Y) or 0, S:reveal(j) or 0
      local a, ah = bfs(j, nipSink, Y)
      local b = bfs(j, teeClosed, Y)
      local dY = Y[j] and 0 or S:region(j, Y)
      print(string.format("  шаг %2d | %-24s | %d / %d | %s%s | %s | %s / %d | %d",
        S.G.depth[i], label(s), rY, rF, tostring(a or "—"), a and (ah and " скр" or " вид") or "", tostring(b or "—"),
        tostring(dY), S:region(j), closeStep - S.G.depth[i]))
    end end end end
S:free()
