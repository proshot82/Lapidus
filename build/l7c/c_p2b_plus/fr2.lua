-- fr2.lua файл.lua "H> F^ ..." — сыграть ходы от старта, затем найти кратчайшее доигрывание и показать кадры.
-- ТОЛЬКО для вывода инструмента (в файлы, журнал и ответы не переносить).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local def = dofile(arg[1])
local lvl = R.compile(def)
local st = R.newState(lvl)
local DIR = { ["^"] = 1, [">"] = 2, ["v"] = 3, ["<"] = 4 }
for tok in (arg[2] or ""):gmatch("%S+") do
  local w = tok:sub(1, 1) == "H" and "head" or "heel"
  local ns, why = R.move(lvl, st, w, DIR[tok:sub(2, 2)])
  assert(ns, "ход невозможен: " .. tok .. " " .. tostring(why))
  st = ns
end
-- BFS
local k0 = R.key(st)
local idx, keys, par, pm = { [k0] = 1 }, { k0 }, { 0 }, { 0 }
local qi, win = 1, nil
while qi <= #keys and not win do
  local id = qi; qi = qi + 1
  local s = R.decode(lvl, keys[id])
  if not s.dead then
    for m = 1, 8 do
      local mm = R.MOVES[m]
      local ns = R.move(lvl, s, mm.which, mm.dir)
      if ns and not ns.dead then
        local k = R.key(ns)
        if not idx[k] then
          keys[#keys + 1] = k; idx[k] = #keys; par[#keys] = id; pm[#keys] = m
          if R.isWin(lvl, ns) then win = #keys; break end
        end
      end
    end
  end
end
if not win then print("не решается, состояний " .. #keys) return end
local path = {}
local x = win
while x ~= 1 do table.insert(path, 1, x); x = par[x] end
table.insert(path, 1, 1)
local function show(s, label)
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for xx = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+xx]; rows[y][xx] = c == 1 and "#" or "." end end
  for q, p in ipairs(lvl.pieces) do if s.pos[q] ~= 0 then local cx, cy = R.xy(lvl, s.pos[q]); local ch = p.tag and p.tag:sub(1,1) or (p.source and "S" or "F"); if p.movable and s.fixed[q] then ch = ch:upper() end; rows[cy][cx] = ch end end
  for i, c in ipairs(s.body) do local cx, cy = R.xy(lvl, c); rows[cy][cx] = (i == #s.body) and "H" or ((i == 1) and "f" or "o") end
  local out = { label }
  for y = 1, lvl.H do out[#out+1] = table.concat(rows[y]) end
  return out
end
local frames = {}
for i, id in ipairs(path) do
  local s = R.decode(lvl, keys[id])
  frames[#frames+1] = show(s, i == 1 and "от" or ((i-1) .. R.moveName(pm[id]):gsub("heel", "f"):gsub("head", "H"):gsub(":", ""):sub(1, 3)))
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
