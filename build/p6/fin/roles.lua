-- абляции роли для ядра «За собой»: luajit roles.lua файл
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local cq, nq
for q, p in ipairs(lvl.pieces) do if p.tag == "cpl" then cq = q elseif p.tag == "nip" then nq = q end end
local G0 = SV.explore(lvl, 3000000)
local win = R.decode(lvl, G0.keys[G0.firstWin])
local nx = R.xy(lvl, win.pos[nq])
SV.freeGraph(G0)
local filters = {
  { "запрет «муфта одна» (закрепление только парой)", function(l, st, ns)
      return not (ns.pos[cq] ~= 0 and ns.pos[nq] ~= 0 and ns.fixed[cq] ~= ns.fixed[nq]) end },
  { "запрет «ниппель на Лапидусе над устьем»", function(l, st, ns)
      local c = ns.pos[nq]
      if c == 0 or ns.fixed[nq] then return true end
      local x = R.xy(l, c)
      if x ~= nx then return true end
      local below = l.nb[c][3]
      for _, b in ipairs(ns.body) do if b == below then return false end end
      return true end },
  { "запрет пары (для сведения)", function(l, st, ns)
      return not (ns.pos[cq] ~= 0 and ns.pos[nq] ~= 0 and ns.asm[cq] == ns.asm[nq] and not ns.fixed[cq]) end },
}
for _, f in ipairs(filters) do
  local G = SV.explore(lvl, 3000000, f[2])
  print(string.format("%s: %s", f[1], (G and G.firstWin) and ("РЕШАЕМ, " .. G.depth[G.firstWin] .. " ходов") or "нерешаем"))
  if G then SV.freeGraph(G) end
end
