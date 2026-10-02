-- gvis.lua — общий «самый широкий честный» видимый проигрыш для разведки (без решений; только правила).
-- local GV = dofile("build/l7c/d_tee_lift/gvis.lua"); def.visibleLoss = GV.make(def)
-- Финальная сборка берётся из единственного выигрышного состояния (считается один раз).
-- Правила (видно, если знать финальную сборку):
--  F  деталь закреплена не там, где она в финале;
--  J  две детали свинчены, а в финале они не свинчены;
--  I  деталь, которой в финале нужно быть в другом месте, больше никогда не сдвинется (статично: лежит на твёрдом,
--     вне струи, и в каждую сторону либо упор, либо толкателю негде встать);
--  X  лишняя деталь навсегда (как в I) лежит на клетке финальной сборки (своей или чужой, включая тело Лапидуса);
--  L  деталь ниже своей финальной строки лежит на твёрдом вне столба, и в столб по её ряду её не втолкнуть
--     (нет фонтана или путь по ряду упирается в твёрдое).
local R = require("core.rules")
local SV = require("solver.solve")
local M = {}

function M.final(def)
  local lvl = R.compile(def)
  local G = SV.explore(lvl, 3000000)
  assert(G and G.firstWin, "нет решения")
  local st = R.decode(lvl, G.keys[G.firstWin])
  SV.freeGraph(G)
  return st
end

function M.make(def, opts)
  opts = opts or {}
  local fin
  return function(lvl, st)
    fin = fin or M.final(def)
    local P = lvl.pieces
    local occ = {}
    for q = 1, #st.pos do if st.pos[q] ~= 0 then occ[st.pos[q]] = q end end
    local function solid(c) if c == 0 or lvl.cell[c] == R.WALL then return true end local r = occ[c]; return r and st.fixed[r] end
    -- F
    for q, p in ipairs(P) do
      if p.movable and st.pos[q] ~= 0 and st.fixed[q] and st.pos[q] ~= fin.pos[q] then return true end
    end
    -- J
    for a = 1, #P do for b = a + 1, #P do
      if P[a].movable and P[b].movable and st.pos[a] ~= 0 and st.pos[b] ~= 0 then
        local joined = (not st.fixed[a]) and (not st.fixed[b]) and st.asm[a] == st.asm[b]
        if joined then
          local d = R.dirBetween(lvl, fin.pos[a], fin.pos[b])
          local fj = d and P[a].ports[d] and P[b].ports[R.OPP[d]] and R.match(P[a].ports[d], P[b].ports[R.OPP[d]])
          if not fj then return true end
        end
      end
    end end
    -- jets
    local jet, colTop = {}, {}
    local anyUp = false
    for _, j in ipairs(R.jets(lvl, st)) do
      for _, c in ipairs(j.cells) do jet[c] = true end
      if j.dir == R.UP and #j.cells > 0 then anyUp = true; local t = lvl.nb[j.cells[#j.cells]][R.UP]; if t ~= 0 then colTop[t] = true end; for _, c in ipairs(j.cells) do colTop[c] = true end end
    end
    local finalCells = {}
    for q = 1, #fin.pos do if fin.pos[q] ~= 0 then finalCells[fin.pos[q]] = q end end
    for _, c in ipairs(fin.body) do finalCells[c] = "L" end
    local function immobile(c)
      if jet[c] or colTop[c] then return false end
      if not solid(lvl.nb[c][R.DOWN]) then return false end
      for d = 1, 4 do
        if d ~= R.DOWN then
          local fwd, back = lvl.nb[c][d], lvl.nb[c][R.OPP[d]]
          if d == R.UP then -- толкнуть вверх можно только снизу — снизу твёрдое, нельзя
          elseif not solid(fwd) and not solid(back) then return false end
        end
      end
      return true
    end
    for q, p in ipairs(P) do
      local c = st.pos[q]
      if p.movable and c ~= 0 and not st.fixed[q] then
        -- I / X
        if immobile(c) then
          if c ~= fin.pos[q] then return true end
        end
        -- L
        local fy = select(2, R.xy(lvl, fin.pos[q]))
        local x, y = R.xy(lvl, c)
        if y > fy and solid(lvl.nb[c][R.DOWN]) and not jet[c] and not colTop[c] then
          local ok = false
          if anyUp then
            for _, dd in ipairs({ R.LEFT, R.RIGHT }) do
              local t = c
              while true do
                t = lvl.nb[t][dd]
                if t == 0 or solid(t) then break end
                if colTop[t] then ok = true; break end
              end
            end
          end
          if not ok and not opts.noL then return true end
        end
      end
    end
    return false
  end
end
return M
