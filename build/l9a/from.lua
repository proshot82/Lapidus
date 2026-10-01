-- build/l9a/from.lua файл.lua ход… — сыграть ходы (H|f + u|r|d|l), затем BFS из полученного состояния:
-- печатает, решаемо ли оттуда, за сколько ходов, и кадры кратчайшего продолжения (только в терминал, для отладки автора).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local def = dofile(arg[1])
local lvl = R.compile(def)
local SYM = { source = "S", fixture = "F", stub = "T", pipe = "=", fitting = "b", porcelain = "P" }
local function show(s, label)
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  if not s.dead then
    for _, j in ipairs(R.jets(lvl, s)) do for _, c in ipairs(j.cells) do local x, y = R.xy(lvl, c); rows[y][x] = (j.dir == R.UP) and "^" or ((j.dir == R.DOWN) and "v" or ((j.dir == R.RIGHT) and ">" or "<")) end end
  end
  for q, pp in ipairs(lvl.pieces) do if s.pos[q] ~= 0 then local x, y = R.xy(lvl, s.pos[q]); local ch = pp.movable and (pp.tag or "b"):sub(1,1) or SYM[pp.kind]; if pp.movable then ch = s.fixed[q] and ch:upper() or ch:lower() end; rows[y][x] = ch end end
  if not s.dead then for i, c in ipairs(s.body) do local x, y = R.xy(lvl, c); rows[y][x] = (i == #s.body) and "H" or ((i == 1) and "f" or "o") end end
  local out = { label }
  for y = 1, lvl.H do out[#out+1] = table.concat(rows[y]) end
  return out
end
local st = R.newState(lvl)
for i = 2, #arg do
  local w = arg[i]:sub(1,1) == "H" and "head" or "heel"
  local d = R.DIRINDEX[({u="up", r="right", d="down", l="left"})[arg[i]:sub(2,2)]]
  local ns, kind = R.move(lvl, st, w, d)
  if not ns then print("ход " .. arg[i] .. " невозможен: " .. tostring(kind)); return end
  st = ns
end
-- BFS от st
local k0 = R.key(st)
local index, keys, parent, pmove = { [k0] = 1 }, { k0 }, { 0 }, { 0 }
local win
local qi = 1
while qi <= #keys and not win do
  local id = qi; qi = qi + 1
  local s = R.decode(lvl, keys[id])
  if not s.dead then
    for m = 1, 8 do
      local mm = R.MOVES[m]
      local ns = R.move(lvl, s, mm.which, mm.dir)
      if ns then
        local k = R.key(ns)
        if not index[k] then
          local nid = #keys + 1
          if nid > 2000000 then print("CAP"); return end
          keys[nid] = k; index[k] = nid; parent[nid] = id; pmove[nid] = m
          if not ns.dead and R.isWin(lvl, ns) then win = nid; break end
        end
      end
    end
  end
end
if not win then print(string.format("из этого состояния НЕРЕШАЕМО (достижимо %d состояний)", #keys)); local f = show(st, "состояние"); for _, l in ipairs(f) do print(l) end; return end
local path, x = {}, win
while x ~= 1 do table.insert(path, 1, x); x = parent[x] end
print(string.format("решаемо: ещё %d ходов (достижимо %d)", #path, #keys))
local frames = { show(st, "здесь") }
for i, id in ipairs(path) do
  frames[#frames+1] = show(R.decode(lvl, keys[id]), i .. R.moveName(pmove[id]):gsub("heel", "f"):gsub("head", "H"):gsub(":", ""):sub(1, 3))
end
local per = math.max(1, math.floor(120 / (lvl.W + 2)))
for k = 1, #frames, per do
  for line = 1, #frames[k] do
    local parts = {}
    for j = k, math.min(k + per - 1, #frames) do parts[#parts+1] = string.format("%-" .. (lvl.W + 2) .. "s", frames[j][line] or "") end
    print(table.concat(parts, ""))
  end
  print()
end
