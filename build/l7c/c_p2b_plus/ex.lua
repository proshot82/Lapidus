-- ex.lua файл.lua "подстрока подписи" [N] — показать N примеров тупиковых состояний с подписью (как sig.lua),
-- кадром поля. Только вывод инструмента (это не решение: отдельные состояния).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local pat = arg[2]
local N = tonumber(arg[3] or 3)
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local P = lvl.pieces
local src, fix
for q, p in ipairs(P) do if p.source then src = q elseif p.fixture then fix = q end end
local sx, sy = R.xy(lvl, P[src].start)
local function where(st, q)
  local c = st.pos[q]
  if c == 0 then return "смыт" end
  local x, y = R.xy(lvl, c)
  local s
  if x == sx then
    if st.fixed[q] then
      local nearFix = false
      for d = 1, 4 do if lvl.nb[c][d] == P[fix].start then nearFix = true end end
      s = (nearFix and "Fмойка" or (y >= sy - 3 and "Fниз" or "Fстолб")) .. y
    else s = "столб" .. y end
  else s = ((x < sx) and "Л" or "П") .. (st.fixed[q] and "F" or "") .. y end
  local mates = {}
  for r, p2 in ipairs(P) do
    if r ~= q and p2.movable and st.pos[r] ~= 0 then
      local same = (not st.fixed[q] and not st.fixed[r] and st.asm[q] == st.asm[r])
      if not same and st.fixed[q] and st.fixed[r] then
        local d = R.dirBetween(lvl, c, st.pos[r])
        if d and P[q].ports[d] and P[r].ports[R.OPP[d]] and R.match(P[q].ports[d], P[r].ports[R.OPP[d]]) then same = true end
      end
      if same then mates[#mates + 1] = p2.tag end
    end
  end
  if #mates > 0 then table.sort(mates); s = s .. "+" .. table.concat(mates, "") end
  return s
end
local function sig(st)
  local t = {}
  for q, p in ipairs(P) do if p.movable then t[#t + 1] = p.tag .. ":" .. where(st, q) end end
  local l, r, c = false, false, false
  for _, b in ipairs(st.body) do local x = R.xy(lvl, b); if x < sx then l = true elseif x > sx then r = true else c = true end end
  t[#t + 1] = "Лап:" .. (l and "Л" or "") .. (c and "С" or "") .. (r and "П" or "")
  return table.concat(t, " ")
end
local SYM = { source = "S", fixture = "F" }
local function show(s)
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  for q, pp in ipairs(P) do if s.pos[q] ~= 0 then local x, y = R.xy(lvl, s.pos[q]); local ch = pp.tag and pp.tag:sub(1,1) or SYM[pp.kind]; if pp.movable then ch = s.fixed[q] and ch:upper() or ch:lower() else ch = SYM[pp.kind] end; rows[y][x] = ch end end
  for i, c in ipairs(s.body) do local x, y = R.xy(lvl, c); rows[y][x] = (i == #s.body) and "H" or ((i == 1) and "f" or "o") end
  local out = {}
  for y = 1, lvl.H do out[#out+1] = table.concat(rows[y]) end
  return out
end
local shown = {}
for i = 1, G.n do
  if #shown >= N then break end
  if G.flag[i] == 0 and good[i] ~= 1 then
    local st = R.decode(lvl, G.keys[i])
    if sig(st):find(pat, 1, true) then shown[#shown + 1] = { show(st), G.depth[i] } end
  end
end
for line = 1, lvl.H do
  local parts = {}
  for _, s in ipairs(shown) do parts[#parts + 1] = string.format("%-" .. (lvl.W + 3) .. "s", s[1][line]) end
  print(table.concat(parts))
end
local d = {}
for _, s in ipairs(shown) do d[#d + 1] = "глубина от старта " .. s[2] end
print(table.concat(d, "; "))
SV.freeGraph(G); require("ffi").C.free(good)
