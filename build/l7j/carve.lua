-- build/l7j/carve.lua вход.lua выход.lua — «замуровка»: по одной замуровывает мёртвые клетки (стена не меняет кратчайшее,
-- финальную сборку и абляции), выбирая ту, что сильнее поднимает долю скрытых и сохраняет дверь и глубину. Решения не печатает.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local MET = dofile("build/l7j/met.lua")
local src = arg[1]
local base = dofile(src)
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
local cur = SV.deepcopy(base)
local r0 = MET.eval(cur, 3000000)
local fk0, opt0 = finalKey(r0), r0.opt
print(string.format("база: ходов %d, скрытых %.0f%%, глубина %d, двери %d/%d, сост %d", r0.opt, r0.hid, r0.deep, r0.d1, r0.d2, r0.n))
local W, H = #cur.grid[1], #cur.grid
while true do
  local best, bestR, bx, by
  for y = 2, H - 1 do for x = 2, W - 1 do
    if cur.grid[y]:sub(x, x) == "." and not occupied(cur, x, y) then
      local d = SV.deepcopy(cur)
      setCell(d, x, y, "#")
      local r = MET.eval(d, 3000000)
      if not r.err and r.opt == opt0 and finalKey(r) == fk0 and r.ncfg == 1 and r.deep >= 8 and r.d1 + r.d2 >= 1 then
        local ok = true
        for _, a in ipairs(SV.ablations(d, { cap = 3000000 })) do if a.solvable ~= false then ok = false end end
        if ok and (not bestR or r.hid > bestR.hid) then best, bestR, bx, by = d, r, x, y end
      end
    end
  end end
  if not best then break end
  cur = best
  print(string.format("стена (%d,%d): скрытых %.0f%%, глубина %d, двери %d/%d, ширина %d, прогулка %d, сост %d", bx, by, bestR.hid, bestR.deep, bestR.d1, bestR.d2, bestR.width, bestR.walk, bestR.n))
  io.stdout:flush()
  -- запись промежуточного результата
  local f = io.open(src):read("*a")
  local rows = {}
  for _, row in ipairs(cur.grid) do rows[#rows + 1] = string.format('    "%s",', row) end
  local out = f:gsub("  grid = {.-\n  },", function() return "  grid = {\n" .. table.concat(rows, "\n") .. "\n  }," end, 1)
  local g = io.open(arg[2], "w"); g:write(out); g:close()
end
print("готово")
