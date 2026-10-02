-- build/l7v_c/reach.lua "<префикс ходов>" "<конфигурация деталей>" [file] — BFS по графу от состояния после префикса
-- до ближайшего состояния с заданной конфигурацией (строка как у census: tee(x,y)F plug(..) nip(..)).
-- Печатает ходы и доску (только в вывод инструмента), живость каждого состояния пути.
local M = dofile("build/l7v_c/lib.lua")
local R = M.R
local def, lvl = M.load(arg[3])
local G, good = M.graph(def, lvl)
local VL = M.V.compute(lvl, G, def, good)
local st = R.newState(lvl)
local fin, n, err = M.apply(lvl, st, arg[1] or "")
if err then print(err) return end
local from = G.index[R.key(fin)]
local target = arg[2]
local avoid = arg[4] -- шаблон конфигурации, через которую идти нельзя (например "tee%(%d,7%)")
local ES, E = G.eStart.p, G.edges.p
local prev, pm = { [from] = 0 }, {}
local q, h, found = { from }, 1, nil
while h <= #q do
  local u = q[h]; h = h + 1
  local su = R.decode(lvl, G.keys[u])
  if M.cfg(lvl, su) == target and u ~= from then found = u break end
  if G.flag[u] == 0 then
    for e = ES[u - 1], ES[u] - 1 do
      local v = E[e]
      if not prev[v] then
        local ok = true
        if avoid then ok = not M.cfg(lvl, R.decode(lvl, G.keys[v])):find(avoid) end
        if ok then prev[v] = u; q[#q + 1] = v end
      end
    end
  end
end
if not found then print("недостижимо из этого состояния: " .. target .. " (обойдено " .. #q .. ")") return end
local path = {}
local x = found
while x ~= from do table.insert(path, 1, x); x = prev[x] end
local cur = fin
local names = {}
for _, v in ipairs(path) do
  local mv
  for k = 1, 8 do local t = R.move(lvl, cur, R.MOVES[k].which, R.MOVES[k].dir); if t and R.key(t) == G.keys[v] then mv = k break end end
  names[#names + 1] = R.moveName(mv) .. (good[v] == 1 and "" or (VL.newbie[v] and "(ВИДИМО)" or "(скрыто)"))
  cur = R.decode(lvl, G.keys[v])
end
print(string.format("путь %d ходов (от глубины %d): %s", #path, G.depth[from], table.concat(names, " ")))
print(M.show(lvl, cur, "итог  " .. M.cfg(lvl, cur) .. "  живое=" .. tostring(good[found] == 1) .. " видимо=" .. tostring(VL.newbie[found])))
