-- build/l6j/deadcells.lua файл.lua — «замуровка»: каждую свободную клетку (не занятую объектами и не стартовую клетку
-- Лапидуса) по очереди делаем стеной и смотрим, меняется ли кратчайшее решение и решаемость абляций.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local path = arg[1]
local function load() return dofile(path) end
local base = load()
local lvl0 = R.compile(base)
local function solve(def)
  local lvl = R.compile(def)
  local ok = pcall(R.validate, lvl)
  local G = SV.explore(lvl, 2000000)
  if not G then return "CAP" end
  local r
  if G.firstWin then r = { opt = G.depth[G.firstWin], n = G.n, wincfg = R.key(R.decode(lvl, G.keys[G.firstWin])):sub(-2 * #lvl.pieces) } else r = { opt = nil, n = G.n } end
  SV.freeGraph(G)
  return r
end
local b = solve(base)
print(string.format("база: ходов %s, состояний %d", tostring(b.opt), b.n))
local occ = {}
for _, o in ipairs(base.objects) do
  if o.kind == "lapidus" then for _, c in ipairs(o.cells) do occ[c[2] * 100 + c[1]] = true end else occ[o.at[2] * 100 + o.at[1]] = true end
end
for y = 2, lvl0.H - 1 do
  for x = 2, lvl0.W - 1 do
    if lvl0.cell[R.idx(lvl0, x, y)] == 0 and not occ[y * 100 + x] then
      local def = load()
      local row = def.grid[y]
      def.grid[y] = row:sub(1, x - 1) .. "#" .. row:sub(x + 1)
      local okc, r = pcall(solve, def)
      local abl = ""
      if okc and r.opt then
        local res = SV.ablations(def, { cap = 2000000 })
        local bad = {}
        for _, a in ipairs(res) do if a.solvable ~= false then bad[#bad + 1] = a.name end end
        abl = (#bad > 0) and (" АБЛЯЦИИ РЕШАЕМЫ: " .. table.concat(bad, ", ")) or ""
      end
      local s
      if not okc then s = "ошибка" elseif not r.opt then s = "НЕРЕШАЕМ" else s = string.format("ходов %d (%+d), состояний %d%s%s", r.opt, r.opt - b.opt, r.n, (r.wincfg ~= b.wincfg) and " ДРУГОЙ ФИНАЛ" or "", abl) end
      print(string.format("стена в (%d,%d): %s", x, y, s))
    end
  end
end
