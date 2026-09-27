-- build/l6/starts.lua база.lua [minLen] [maxLen] — перебор стартов: Лапидус (все формы длины L) + ниппель на его спине.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local ST = require("solver.strict")
local base = dofile(arg[1])
local L1, L2 = tonumber(arg[2] or "3"), tonumber(arg[3] or "4")
local nipTag = arg[4] or "nip"
local W, H = #base.grid[1], #base.grid
local function empty(x, y, occ)
  if x < 1 or x > W or y < 1 or y > H then return false end
  if base.grid[y]:sub(x, x) ~= "." then return false end
  return not occ[y * 100 + x]
end
local occ0 = {}
local nipIdx
for i, o in ipairs(base.objects) do
  if o.at then occ0[o.at[2] * 100 + o.at[1]] = true end
  if o.tag == nipTag then nipIdx = i end
end
if nipIdx then occ0[base.objects[nipIdx].at[2] * 100 + base.objects[nipIdx].at[1]] = nil end
local results = {}
local seen = {}
local function tryShape(cells)
  -- ниппель на одной из клеток тела (сверху)
  for _, c in ipairs(cells) do
    local nx, ny = c[1], c[2] - 1
    local onBody = false
    for _, c2 in ipairs(cells) do if c2[1] == nx and c2[2] == ny then onBody = true end end
    if not onBody and empty(nx, ny, occ0) then
      local d = SV.deepcopy(base)
      for _, o in ipairs(d.objects) do
        if o.kind == "lapidus" then o.cells = {}; for k, c3 in ipairs(cells) do o.cells[k] = { c3[1], c3[2] } end; o.head = #cells end
        if o.tag == nipTag then o.at = { nx, ny } end
      end
      local ok, lvl = pcall(R.compile, d)
      if ok and #R.validate(lvl) == 0 then
        local st = R.newState(lvl)
        local key = R.key(st)
        if not seen[key] and not st.dead then
          seen[key] = true
          -- ниппель должен остаться на спине после устаканивания
          local q = nipIdx
          local stays = st.pos[q] == (ny - 1) * W + nx
          if stays then
            local res = SV.analyze(d, { cap = 400000 })
            if res.solvable then
              local abl = SV.ablations(d, { cap = 400000 })
              local ablok = true
              for _, a in ipairs(abl) do if a.solvable ~= false then ablok = false end end
              local sx = ST.check(d, 400000)
              local cc = {}; for _, c3 in ipairs(cells) do cc[#cc+1] = { c3[1], c3[2] } end
              results[#results + 1] = { d = d, res = res, sx = sx, ablok = ablok, cells = cc, nip = { nx, ny } }
            end
          end
        end
      end
    end
  end
end
local function extend(cells, used, L)
  if #cells == L then
    tryShape(cells)
    return
  end
  local c = cells[#cells]
  for _, dxy in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
    local x, y = c[1] + dxy[1], c[2] + dxy[2]
    if empty(x, y, occ0) and not used[y * 100 + x] then
      used[y * 100 + x] = true
      cells[#cells + 1] = { x, y }
      extend(cells, used, L)
      cells[#cells] = nil
      used[y * 100 + x] = nil
    end
  end
end
for L = L1, L2 do
  for y = 1, H do for x = 1, W do
    if empty(x, y, occ0) then extend({ { x, y } }, { [y * 100 + x] = true }, L) end
  end end
end
table.sort(results, function(a, b)
  local sa = (a.ablok and 1000 or 0) + (a.sx and a.sx.monkey <= 1 and 500 or 0) + (a.sx and a.sx.maxWidth <= 3 and 300 or 0) + a.res.minMoves
  local sb = (b.ablok and 1000 or 0) + (b.sx and b.sx.monkey <= 1 and 500 or 0) + (b.sx and b.sx.maxWidth <= 3 and 300 or 0) + b.res.minMoves
  return sa > sb
end)
print("решаемых стартов: " .. #results)
for i = 1, math.min(tonumber(arg[5] or "12"), #results) do
  local r = results[i]
  local cs = {}
  for _, c in ipairs(r.cells) do cs[#cs + 1] = c[1] .. "," .. c[2] end
  print(string.format("%2d. lap[%s] nip(%d,%d): moves=%d states=%d dead=%.1f fb=%s win=%d abl=%s monkey=%.2f short=%d w=%d",
    i, table.concat(cs, " "), r.nip[1], r.nip[2], r.res.minMoves, r.res.states, r.res.deadPct, tostring(r.res.falseBranches),
    r.res.winStates, tostring(r.ablok), r.sx and r.sx.monkey or -1, r.sx and r.sx.shortest or -1, r.sx and r.sx.maxWidth or -1))
end
