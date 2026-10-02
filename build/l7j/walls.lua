-- build/l7j/walls.lua файл.lua [пары] [часть/частей] — пробует добавить одну (или две) стены в свободные клетки и печатает
-- метрики (ходов, скрытые, глубина, двери, ширина, прогулка). Финальная сборка должна остаться прежней. Решения не печатает.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local MET = dofile("build/l7j/met.lua")
local base = dofile(arg[1])
local pairsMode = arg[2] == "2"
local part, parts = 1, 1
if arg[3] then part, parts = arg[3]:match("(%d+)/(%d+)"); part, parts = tonumber(part), tonumber(parts) end
local function finalKey(r)
  local t = {}
  for q, p in ipairs(r.lvl.pieces) do if p.movable then t[#t + 1] = r.win.pos[q] .. (r.win.fixed[q] and "f" or "") end end
  return table.concat(t, ",")
end
local function setCell(def, x, y, ch) local row = def.grid[y]; def.grid[y] = row:sub(1, x - 1) .. ch .. row:sub(x + 1) end
local function occupied(d, x, y)
  for _, o in ipairs(d.objects) do
    if o.kind == "lapidus" then for _, c in ipairs(o.cells) do if c[1] == x and c[2] == y then return true end end
    elseif o.at[1] == x and o.at[2] == y then return true end
  end
  return false
end
local r0 = MET.eval(base, 3000000)
local fk0 = finalKey(r0)
print(string.format("база: ходов %d скр %.0f%% глуб %d двери %d/%d шир %d прог %d сост %d", r0.opt, r0.hid, r0.deep, r0.d1, r0.d2, r0.width, r0.walk, r0.n))
local W, H = #base.grid[1], #base.grid
local cells = {}
for y = 2, H - 1 do for x = 2, W - 1 do
  if base.grid[y]:sub(x, x) == "." and not occupied(base, x, y) then cells[#cells + 1] = { x, y } end
end end
local combos = {}
for i = 1, #cells do
  if pairsMode then for j = i + 1, #cells do combos[#combos + 1] = { cells[i], cells[j] } end
  else combos[#combos + 1] = { cells[i] } end
end
for k = part, #combos, parts do
  local cmb = combos[k]
  local d = SV.deepcopy(base)
  local nm = {}
  for _, c in ipairs(cmb) do setCell(d, c[1], c[2], "#"); nm[#nm + 1] = c[1] .. "," .. c[2] end
  local r = MET.eval(d, 3000000)
  if not r.err and r.ncfg == 1 and finalKey(r) == fk0 then
    if r.opt >= (tonumber(os.getenv("MINOPT") or 0)) then
      print(string.format("%-12s ходов %d скр %.0f%% глуб %d двери %d/%d шир %d прог %d сост %d", table.concat(nm, " "), r.opt, r.hid, r.deep, r.d1, r.d2, r.width, r.walk, r.n))
      io.stdout:flush()
    end
  end
end
