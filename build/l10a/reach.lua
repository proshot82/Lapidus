-- build/l10a/reach.lua файл.lua [ходы…] -- tag x y [F|f] [tag x y …] — сыграть ходы, затем BFS и ответить, достижимо ли
-- состояние, где детали стоят в указанных клетках (F — закреплена, f — свободна, иначе любая). Печатает число состояний
-- и минимальную глубину (ходы не печатаются). Отладка автора.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local def = dofile(arg[1])
local lvl = R.compile(def)
local st = R.newState(lvl)
local i = 2
while arg[i] and arg[i] ~= "--" do
  local m = arg[i]
  local which = (m:sub(1, 1) == "H") and "head" or "heel"
  local d = ({ u = R.UP, r = R.RIGHT, d = R.DOWN, l = R.LEFT })[m:sub(2, 2)]
  local ns = R.move(lvl, st, which, d)
  if not ns then print("ход " .. m .. " невозможен") return end
  st = ns; i = i + 1
end
i = i + 1
local want = {}
while arg[i] do
  local q
  for k, p in ipairs(lvl.pieces) do if p.tag == arg[i] then q = k end end
  want[#want + 1] = { q = q, c = R.idx(lvl, tonumber(arg[i + 1]), tonumber(arg[i + 2])), f = arg[i + 3] }
  i = i + 4
end
local function ok(s)
  for _, w in ipairs(want) do
    if s.pos[w.q] ~= w.c then return false end
    if w.f == "F" and not s.fixed[w.q] then return false end
    if w.f == "f" and s.fixed[w.q] then return false end
  end
  return true
end
local SHOW = os.getenv("SHOW")
local function show(s)
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  for qq, pp in ipairs(lvl.pieces) do if s.pos[qq] ~= 0 then local x, y = R.xy(lvl, s.pos[qq]); local ch = pp.movable and (pp.tag or "b"):sub(1,1) or ({ source = "S", fixture = "F", stub = "T", pipe = "=" })[pp.kind]; if pp.movable then ch = s.fixed[qq] and ch:upper() or ch:lower() end; rows[y][x] = ch end end
  if not s.dead then for k, c in ipairs(s.body) do local x, y = R.xy(lvl, c); rows[y][x] = (k == #s.body) and "H" or ((k == 1) and "f" or "o") end end
  for y = 1, lvl.H do print(table.concat(rows[y])) end
end
local seen = { [R.key(st)] = true }
local q, depth, h = { st }, { 0 }, 1
local found, wins = nil, 0
while h <= #q do
  local s = q[h]; local d = depth[h]; h = h + 1
  if not s.dead then
    if ok(s) and not found then found = d; if SHOW then show(s) end end
    if R.isWin(lvl, s) then wins = wins + 1 end
    for m = 1, 8 do
      local mv = R.MOVES[m]
      local ns = R.move(lvl, s, mv.which, mv.dir)
      if ns then local k = R.key(ns); if not seen[k] then seen[k] = true; q[#q + 1] = ns; depth[#depth + 1] = d + 1 end end
    end
  end
  if #q > 2000000 then print("CAP") break end
end
print(string.format("достижимо состояний %d; искомое: %s; выигрышных %d", #q, found and ("да, глубина " .. found) or "НЕТ", wins))
