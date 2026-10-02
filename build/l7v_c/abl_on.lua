-- build/l7v_c/abl_on.lua файл.lua — фильтр teeNoRow7 (тройник никогда в коридоре) на варианте раскладки:
-- жива ли вторая стратегия без данной клетки.
local M = dofile("build/l7v_c/lib.lua")
local R = M.R
local def, lvl = M.load(arg[1])
local k = {}
for q, p in ipairs(lvl.pieces) do if p.tag then k[p.tag] = q end end
local function row(c) local _, y = R.xy(lvl, c); return y end
local G = M.SV.explore(lvl, 3000000, function(lvl, st, ns) local c = ns.pos[k.tee]; return not (c ~= 0 and row(c) == 7) end)
print(def.name .. ", тройник не в коридоре: " .. (G.firstWin and ("РЕШАЕМ за " .. G.depth[G.firstWin]) or "нерешаем") .. " (состояний " .. G.n .. ")")
M.SV.freeGraph(G)
