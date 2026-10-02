-- build/l9v/aha.lua файл.lua — обязательность «ага» во всех кратчайших решениях: перебор кратчайших путей (DAG)
-- и подсчёт, сколько из них обладают каждым свойством. Ходы не печатаются.
local L = dofile("build/l9v/lib.lua")
local S = L.load(arg[1])
local R = L.R
local lvl, W = S.lvl, S.lvl.W
local function idx(x, y) return (y - 1) * W + x end
local tee, plug, nip
for q, p in ipairs(lvl.pieces) do if p.tag == "tee" then tee = q elseif p.tag == "plug" then plug = q elseif p.tag == "nip" then nip = q end end
local dw, opt = S:distWin(), S:opt()
local paths = {}
local function dfs(i, acc)
  if S.flag[i] == 1 then local cp = {} for k = 1, #acc do cp[k] = acc[k] end; paths[#paths+1] = cp; return end
  for e = S.ES[i-1], S.ES[i]-1 do local j = S.E[e]
    if dw[j] and dw[j] == dw[i] - 1 and S.G.depth[j] == S.G.depth[i] + 1 then acc[#acc+1] = j; dfs(j, acc); acc[#acc] = nil end end
end
dfs(1, { 1 })
print("кратчайших путей: " .. #paths)
local props = {
  { "вода раньше любой детали (тройник/заглушка не сдвинуты до намокания)", function(p)
      local s0 = S:st(p[1])
      for _, i in ipairs(p) do local s = S:st(i)
        if S:wet(s) then return true end
        if s.pos[tee] ~= s0.pos[tee] or s.pos[plug] ~= s0.pos[plug] then return false end end
      return true end },
  { "тройник стоит на гребне ближнего фонтана (7,4)", function(p) for _, i in ipairs(p) do if S:st(i).pos[tee] == idx(7, 4) and not S:st(i).fixed[tee] then return true end end return false end },
  { "тройник стоит на гребне дальнего фонтана (8,4)", function(p) for _, i in ipairs(p) do if S:st(i).pos[tee] == idx(8, 4) and not S:st(i).fixed[tee] then return true end end return false end },
  { "заглушка стоит на гребне ближнего (7,4)", function(p) for _, i in ipairs(p) do if S:st(i).pos[plug] == idx(7, 4) and not S:st(i).fixed[plug] then return true end end return false end },
  { "заглушка стоит на гребне дальнего (8,4)", function(p) for _, i in ipairs(p) do if S:st(i).pos[plug] == idx(8, 4) and not S:st(i).fixed[plug] then return true end end return false end },
  { "заглушка в столбе дальнего (8,5) перед прикручиванием", function(p) for _, i in ipairs(p) do if S:st(i).pos[plug] == idx(8, 5) then return true end end return false end },
  { "тройник закреплён раньше заглушки", function(p) for _, i in ipairs(p) do local s = S:st(i); if s.fixed[tee] and not s.fixed[plug] then return true end; if s.fixed[plug] and not s.fixed[tee] then return false end end return false end },
  { "голова заходит в столб ближнего фонтана при прикрученных ногах", function(p)
      for _, i in ipairs(p) do local s = S:st(i); local pc = R.occupancy(s)
        local hx, hy = R.xy(lvl, s.body[#s.body])
        if hx == 7 and (hy == 5 or hy == 6) and R.endScrew(lvl, s, pc, "heel") then return true end end
      return false end },
}
for _, pr in ipairs(props) do
  local c = 0
  for _, p in ipairs(paths) do if pr[2](p) then c = c + 1 end end
  print(string.format("  %d из %d: %s", c, #paths, pr[1]))
end
-- где кратчайшие пути расходятся (шаги с шириной > 1)
local w = {}
for _, p in ipairs(paths) do for k, i in ipairs(p) do w[k-1] = w[k-1] or {}; w[k-1][i] = true end end
local t = {}
for d = 0, opt do local c = 0; for _ in pairs(w[d] or {}) do c = c + 1 end; if c > 1 then t[#t+1] = d .. ":" .. c end end
print("шаги, где кратчайшие расходятся (шаг:состояний): " .. table.concat(t, " "))
S:free()
