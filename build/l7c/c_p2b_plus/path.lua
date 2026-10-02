-- path.lua файл.lua "цель" ["запрет"] — кратчайший путь от старта до состояния, где выражение «цель» истинно, не заходя
-- в состояния с «запрет»; кадры — ТОЛЬКО вывод инструмента (в файлы, журнал и ответы не переносить).
-- В выражениях доступны: st, lvl, R, T (номера деталей по тегам), X(q) и Y(q) — клетка детали, F(q) — закреплена,
-- A(q) — номер сборки, col — x столба.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local def = dofile(arg[1])
local lvl = R.compile(def)
local T, col = {}, nil
for q, p in ipairs(lvl.pieces) do if p.tag then T[p.tag] = q end; if p.source then col = (R.xy(lvl, p.start)) end end
local function mk(src)
  if not src or src == "" then return nil end
  local env = setmetatable({ R = R, lvl = lvl, T = T, col = col }, { __index = _G })
  local f = assert(load("local st = ...; local function X(q) if st.pos[q] == 0 then return 0 end return (R.xy(lvl, st.pos[q])) end; local function Y(q) if st.pos[q] == 0 then return 0 end local _, y = R.xy(lvl, st.pos[q]); return y end; local function F(q) return st.fixed[q] end; local function A(q) return st.asm[q] end; return " .. src, "expr", "t", env))
  return f
end
local goal, ban = mk(arg[2]), mk(arg[3])
local st0 = R.newState(lvl)
local keys, par, idx = { R.key(st0) }, { 0 }, {}
idx[keys[1]] = 1
local qi, hit = 1, nil
if goal(st0) then hit = 1 end
while qi <= #keys and not hit do
  local s = R.decode(lvl, keys[qi])
  local id = qi; qi = qi + 1
  if not s.dead then
    for m = 1, 8 do
      local mm = R.MOVES[m]
      local ns = R.move(lvl, s, mm.which, mm.dir)
      if ns and not ns.dead and not (ban and ban(ns)) then
        local k = R.key(ns)
        if not idx[k] then
          keys[#keys + 1] = k; idx[k] = #keys; par[#keys] = id
          if goal(ns) then hit = #keys; break end
        end
      end
    end
  end
end
if not hit then print("недостижимо (" .. #keys .. " сост.)"); return end
local chain, x = {}, hit
while x ~= 0 do table.insert(chain, 1, x); x = par[x] end
local frames = {}
for i, id in ipairs(chain) do
  local s = R.decode(lvl, keys[id])
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for xx = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+xx]; rows[y][xx] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  for q, p in ipairs(lvl.pieces) do if s.pos[q] ~= 0 then local cx, cy = R.xy(lvl, s.pos[q]); local ch = p.tag and p.tag:sub(1,1) or (p.source and "S" or "F"); if p.movable and s.fixed[q] then ch = ch:upper() end; rows[cy][cx] = ch end end
  for j, c in ipairs(s.body) do local cx, cy = R.xy(lvl, c); rows[cy][cx] = (j == #s.body) and "H" or ((j == 1) and "f" or "o") end
  local out = { tostring(i - 1) }
  for y = 1, lvl.H do out[#out + 1] = table.concat(rows[y]) end
  frames[#frames + 1] = out
end
local per = math.max(1, math.floor(120 / (lvl.W + 2)))
for i = 1, #frames, per do
  for line = 1, lvl.H + 1 do
    local t = {}
    for j = i, math.min(#frames, i + per - 1) do t[#t + 1] = string.format("%-" .. (lvl.W + 2) .. "s", frames[j][line]) end
    print(table.concat(t))
  end
  print()
end
