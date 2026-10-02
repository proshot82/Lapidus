-- build/l9a/aha9.lua файл.lua — обязательность «ага» g18 во всех кратчайших решениях (по образцу build/l9v/aha.lua).
-- Свойства общими словами; ходы не печатаются.
local L = dofile("build/l9v/lib.lua")
local S = L.load(arg[1])
local R = L.R
local lvl, W = S.lvl, S.lvl.W
local function idx(x, y) return (y - 1) * W + x end
local tee, plug
for q, p in ipairs(lvl.pieces) do if p.tag == "tee" then tee = q elseif p.tag == "plug" then plug = q end end
local dw = S:distWin()
local paths = {}
local function dfs(i, acc)
  if S.flag[i] == 1 then local cp = {} for k = 1, #acc do cp[k] = acc[k] end; paths[#paths+1] = cp; return end
  for e = S.ES[i-1], S.ES[i]-1 do local j = S.E[e]
    if dw[j] and dw[j] == dw[i] - 1 and S.G.depth[j] == S.G.depth[i] + 1 then acc[#acc+1] = j; dfs(j, acc); acc[#acc] = nil end end
end
dfs(1, { 1 })
print("кратчайших путей: " .. #paths)
local function anyState(p, f) for _, i in ipairs(p) do if f(S:st(i)) then return true end end return false end
local props = {
  { "вода раньше любой детали", function(p)
      local s0 = S:st(p[1])
      for _, i in ipairs(p) do local s = S:st(i)
        if S:wet(s) then return true end
        if s.pos[tee] ~= s0.pos[tee] or s.pos[plug] ~= s0.pos[plug] then return false end end
      return true end },
  { "стопка в ближнем столбе (тройник над заглушкой на гребне 1)", function(p) return anyState(p, function(s) return s.pos[tee] == idx(7, 3) and s.pos[plug] == idx(7, 4) and not s.fixed[plug] end) end },
  { "тройник на гребне дальнего фонтана", function(p) return anyState(p, function(s) return s.pos[tee] == idx(8, 4) and not s.fixed[tee] end) end },
  { "заглушка придержана в ближнем столбе (7,5), не прикручена", function(p) return anyState(p, function(s) return s.pos[plug] == idx(7, 5) and not s.fixed[plug] end) end },
  { "заглушка подведена вбок во второй столб (8,5) свободной", function(p) return anyState(p, function(s) return s.pos[plug] == idx(8, 5) and not s.fixed[plug] end) end },
  { "стопка во втором столбе: тройник на губе над заглушкой на гребне 2", function(p) return anyState(p, function(s) return s.pos[tee] == idx(8, 3) and s.pos[plug] == idx(8, 4) and not s.fixed[plug] end) end },
  { "тройник на губе (9,3)", function(p) return anyState(p, function(s) return s.pos[tee] == idx(9, 3) end) end },
  { "тройник закреплён раньше заглушки", function(p) for _, i in ipairs(p) do local s = S:st(i); if s.fixed[tee] and not s.fixed[plug] then return true end; if s.fixed[plug] and not s.fixed[tee] then return false end end return false end },
  { "струя свободного конца (брандспойт) сдвигает тройник по губе", function(p)
      for k = 2, #p do local a, b = S:st(p[k-1]), S:st(p[k])
        if a.pos[tee] == idx(9, 3) and b.pos[tee] ~= idx(9, 3) and not b.fixed[tee] == false then
          local pc = R.occupancy(a); if R.endScrew(lvl, a, pc, "head") or R.endScrew(lvl, a, pc, "heel") then
            local ok = true
            for _, c in ipairs(b.body) do if c == idx(8, 3) then ok = false end end
            if ok then return true end end end end
      return false end },
  { "голова входит в ближний столб при прикрученных ногах", function(p) return anyState(p, function(s) local pc = R.occupancy(s); local hx, hy = R.xy(lvl, s.body[#s.body]); return hx == 7 and (hy == 5 or hy == 6) and R.endScrew(lvl, s, pc, "heel") ~= nil end) end },
}
for _, pr in ipairs(props) do
  local c = 0
  for _, p in ipairs(paths) do if pr[2](p) then c = c + 1 end end
  print(string.format("  %d из %d: %s", c, #paths, pr[1]))
end
local w = {}
for _, p in ipairs(paths) do for k, i in ipairs(p) do w[k-1] = w[k-1] or {}; w[k-1][i] = true end end
local t = {}
for d = 0, S:opt() do local c = 0; for _ in pairs(w[d] or {}) do c = c + 1 end; if c > 1 then t[#t+1] = d .. ":" .. c end end
print("шаги, где кратчайшие расходятся (шаг:состояний): " .. table.concat(t, " "))
S:free()
