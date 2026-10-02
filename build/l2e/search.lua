-- build/l2e/search.lua — перебор вариаций РУЧНОГО скелета: слоты крючьев (буквы в rows) получают none/Н/В,
-- оценка — воротами (build/l2e/ev.lua, тихий режим). Печатает только метрики; лучшие раскладки пишет в build/l2e/out/.
-- luajit build/l2e/search.lua скелет.lua [итераций] [seed]
-- скелет: return { rows = {...}, slots = { a = "right", b = "left", ... }, opts = {...}, fixed = { a = "N" } , starts = { {rows...}, ... } }
package.path = "./?.lua;" .. package.path
local EV = dofile("build/l2e/ev.lua")
local MK = dofile("build/l2e/mk.lua")
local sk = dofile(arg[1])
local iters = tonumber(arg[2] or 400)
math.randomseed(tonumber(arg[3] or os.time()))
local LET = { right = { "R", "r" }, left = { "L", "l" }, up = { "U", "u" }, down = { "D", "d" } }
local slotIds = {}
for id in pairs(sk.slots) do slotIds[#slotIds + 1] = id end
table.sort(slotIds)

local function render(assign, rows)
  local out = {}
  for y, row in ipairs(rows) do
    local s = {}
    for x = 1, #row do
      local ch = row:sub(x, x)
      if sk.slots[ch] then
        local a = assign[ch]
        if a == 0 then s[#s + 1] = sk.air and sk.air[ch] or "#" elseif a == 1 then s[#s + 1] = LET[sk.slots[ch]][1] else s[#s + 1] = LET[sk.slots[ch]][2] end
      else s[#s + 1] = ch end
    end
    out[y] = table.concat(s)
  end
  return out
end

local function score(r, nh)
  if r.fail then return -1000 + (r.n or 0) / 1000 end
  local s = 0
  local function pen(v) s = s - v end
  if r.opt < 15 then pen((15 - r.opt) * 20) elseif r.opt > 40 then pen((r.opt - 40) * 20) end
  local hp = math.min(r.pctAuthor, r.pctPocket12 or r.pctAuthor)
  s = s + math.min(hp, 55) * 2
  if hp < 25 then pen((25 - hp) * 3) end
  s = s + (math.min(r.opt, 32) - 15) * 2
  s = s + math.min(r.events, 8) * 2
  s = s + math.min(r.deep, 12) * 4
  if r.deep < 8 then pen((8 - r.deep) * 10) end
  if r.walk > 6 then pen((r.walk - 6) * 15) end
  if r.forced > 3 then pen((r.forced - 3) * 15) end
  if r.nwcfg > 1 then pen(60) end
  if r.smart > 0.5 then pen(math.min(60, r.smart * 20)) end
  if r.liveMarked > 0 then pen(100) end
  s = s + math.min(r.choices, 12) * 2
  pen(nh * 4); if nh > 6 then pen((nh - 6) * 15) end
  if sk.needFall and r.pathFalls == 0 then pen(60) end
  return s
end

local cache = {}
local function evalAssign(assign, startIdx)
  local key = table.concat((function() local t = {} for _, id in ipairs(slotIds) do t[#t + 1] = assign[id] end t[#t + 1] = startIdx return t end)(), ",")
  if cache[key] then return cache[key] end
  local rows = render(assign, sk.starts and sk.starts[startIdx] or sk.rows)
  local def = MK.build(rows, sk.opts)
  local r = EV.eval(def, nil, true, true)
  local nh = 0
  for _, id in ipairs(slotIds) do if assign[id] ~= 0 then nh = nh + 1 end end
  r.score = score(r, nh); r.rows = rows; r.nh = nh
  cache[key] = r
  return r
end

local function randomAssign()
  local a = {}
  for _, id in ipairs(slotIds) do
    if sk.fixed and sk.fixed[id] then a[id] = sk.fixed[id] == "N" and 1 or (sk.fixed[id] == "V" and 2 or 0)
    else a[id] = math.random(0, 2) end
  end
  return a
end
local function mutate(a)
  local b = {}
  for k, v in pairs(a) do b[k] = v end
  local k = math.random(1, 2)
  for _ = 1, k do
    local id = slotIds[math.random(#slotIds)]
    if not (sk.fixed and sk.fixed[id]) then b[id] = (b[id] + math.random(1, 2)) % 3 end
  end
  return b
end

local nStarts = sk.starts and #sk.starts or 1
local best = {}
local function remember(r)
  best[#best + 1] = r
  table.sort(best, function(x, y) return x.score > y.score end)
  if #best > 12 then best[#best] = nil end
end
local cur, curS = randomAssign(), math.random(nStarts)
local curR = evalAssign(cur, curS)
remember(curR)
local t0 = os.clock()
for it = 1, iters do
  local cand, cs = mutate(cur), curS
  if math.random() < 0.15 then cs = math.random(nStarts) end
  if math.random() < 0.05 then cand = randomAssign() end
  local r = evalAssign(cand, cs)
  if r.score >= curR.score or math.random() < math.exp((r.score - curR.score) / 8) then cur, curS, curR = cand, cs, r end
  remember(r)
  if it % 50 == 0 then
    io.write(string.format("[%d] %.0fs best %.1f cur %.1f\n", it, os.clock() - t0, best[1].score, curR.score)); io.flush()
  end
end
os.execute("mkdir -p build/l2e/out")
local seen = {}
local k = 0
for _, r in ipairs(best) do
  local key = table.concat(r.rows, "|")
  if not seen[key] and not r.fail then
    seen[key] = true; k = k + 1
    local name = string.format("build/l2e/out/%s_s%s_%02d.lua", (arg[1]:match("([^/]+)%.lua$")), tostring(arg[3] or 0), k)
    local f = io.open(name, "w")
    f:write("-- найдено search.lua; метрики: " .. string.format("ходов %d скрытых %.0f%% глубина %d обезьяна %.2f%% прогулка %d вынужд %d развилок %d крючьев %d", r.opt, r.pctAuthor, r.deep, r.smart, r.walk, r.forced, r.choices, r.nh) .. "\n")
    f:write("return { rows = {\n")
    for _, row in ipairs(r.rows) do f:write('"' .. row .. '",\n') end
    f:write("}, opts = " .. (sk.optsSrc or "{}") .. " }\n")
    f:close()
    print(string.format("%s: score %.1f | ходов %d | сост %d | скрытых %.0f%% (never %.0f%%, flip %.0f%%) | глубина %d | обезьяна %.2f%% | прогулка %d вынужд %d развилок %d | конф %d | крючьев %d",
      name, r.score, r.opt, r.n, r.pctAuthor, r.pctNever, r.pctFlip, r.deep, r.smart, r.walk, r.forced, r.choices, r.nwcfg, r.nh))
  end
end
