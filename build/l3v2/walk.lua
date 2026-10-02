-- build/l3v2/walk.lua — где на кратчайшем пути прогулки (фазы без событий с мылом) и что в них возможно:
-- число живых альтернатив и есть ли вообще проигрышные ходы. Без ходов.
local L = dofile("build/l3v/lib.lua")
local ctx = L.load(arg[1] or "build/l3d/s8.lua")
local G, path = ctx.G, L.path(ctx)
local function objs(i) local st = ctx.sts[i] or {pos={}}; return table.concat(st.pos, ",") end
local s, k0 = 0, 1
for k = 1, #path - 1 do
  if objs(path[k]) ~= objs(path[k + 1]) then
    if s > 0 then print(string.format("  прогулка %d ходов: фазы %d–%d", s, k0 - 1, k - 2)) end
    s = 0; k0 = k + 1
  else s = s + 1 end
end
if s > 0 then print(string.format("  прогулка %d ходов: фазы %d–%d (хвост до победы)", s, k0 - 1, #path - 2)) end
local st = ctx.sts[path[#path - s]]
print("  мыло в начале хвоста: " .. L.cfg(ctx, st) .. ", длина Лапидуса " .. #st.body)
L.free(ctx)
