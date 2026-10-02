-- build/l2e/dbg.lua файл.lua — карта клеток, куда тело вообще попадает (по всему графу), и какие крючья берутся.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local EV = dofile("build/l2e/ev.lua")
local def = EV.load(arg[1]); local lvl = R.compile(def)
local G = EV.build(lvl)
local vis, grabbed = {}, {}
for i, st in ipairs(G.sts) do
  if not st.dead then
    for _, c in ipairs(st.body) do vis[c] = (vis[c] or 0) + 1 end
    local piece = R.occupancy(st)
    for _, w in ipairs({ "head", "heel" }) do local q = R.endScrew(lvl, st, piece, w); if q then grabbed[q] = (grabbed[q] or 0) + 1 end end
  end
end
for y = 1, lvl.H do
  local s = {}
  for x = 1, lvl.W do local i = R.idx(lvl, x, y); local c = lvl.cell[i]
    if c == 1 then s[#s+1] = "#" elseif c == 2 then s[#s+1] = "~" else
      local q; for k, p in ipairs(lvl.pieces) do if p.start == i then q = k end end
      if q then s[#s+1] = lvl.pieces[q].kind:sub(1,1):upper() else s[#s+1] = vis[i] and "o" or "." end end end
  print(table.concat(s))
end
for q, p in ipairs(lvl.pieces) do print(string.format("  %s %s (%d,%d): состояний с захватом %d", p.kind, p.tag or "", p.x, p.y, grabbed[q] or 0)) end
print("состояний " .. #G.sts)
