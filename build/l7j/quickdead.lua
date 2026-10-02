-- build/l7j/quickdead.lua файл.lua — быстрый поиск мёртвых клеток (как build/l6j/deadcells.lua, но абляции считаются
-- только для клеток, где стена не меняет кратчайшее и финал). Печатает «мёртвая (x,y)» для клеток-кандидатов в замуровку.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local path = arg[1]
local base = dofile(path)
local function solve(def)
  local lvl = R.compile(def)
  if #R.validate(lvl) > 0 then return nil end
  local G = SV.explore(lvl, 3000000)
  if not G or not G.firstWin then if G then SV.freeGraph(G) end return { opt = nil } end
  local st = R.decode(lvl, G.keys[G.firstWin]); local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then t[#t + 1] = st.pos[q] .. (st.fixed[q] and "f" or "") end end
  local r = { opt = G.depth[G.firstWin], fin = table.concat(t, ","), n = G.n }
  SV.freeGraph(G)
  return r
end
local b = solve(base)
print(string.format("база: ходов %d, состояний %d", b.opt, b.n))
local occ = {}
for _, o in ipairs(base.objects) do
  if o.kind == "lapidus" then for _, c in ipairs(o.cells) do occ[c[2] * 100 + c[1]] = true end else occ[o.at[2] * 100 + o.at[1]] = true end
end
local W, H = #base.grid[1], #base.grid
local dead = {}
for y = 2, H - 1 do for x = 2, W - 1 do
  if base.grid[y]:sub(x, x) == "." and not occ[y * 100 + x] then
    local def = dofile(path)
    local row = def.grid[y]; def.grid[y] = row:sub(1, x - 1) .. "#" .. row:sub(x + 1)
    local r = solve(def)
    local s
    if not r then s = "ошибка" elseif not r.opt then s = "НЕРЕШАЕМ" elseif r.opt ~= b.opt or r.fin ~= b.fin then s = string.format("ходов %d (%+d)%s", r.opt, r.opt - b.opt, r.fin ~= b.fin and " ДРУГОЙ ФИНАЛ" or "") else
      local bad = {}
      for _, a in ipairs(SV.ablations(def, { cap = 3000000 })) do if a.solvable ~= false then bad[#bad + 1] = a.name end end
      if #bad > 0 then s = "абляции решаемы: " .. table.concat(bad, ", ") else s = "МЁРТВАЯ"; dead[#dead + 1] = x .. "," .. y end
    end
    print(string.format("(%d,%d): %s", x, y, s)); io.stdout:flush()
  end
end end
print("мёртвые: " .. table.concat(dead, " "))
