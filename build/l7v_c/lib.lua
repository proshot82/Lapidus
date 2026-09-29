-- build/l7v_c/lib.lua — общие помощники слепого скептика кв. 7 (кандидат c_p2b_plus/c7).
-- Граф состояний, разметки (файл / новичок-скептик / знаток), печать доски (только в вывод инструмента).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local M = {}
M.CAND = "build/l7c/c_p2b_plus/c7.lua"

function M.load(path)
  if path == "" then path = nil end
  local def = dofile(path or M.CAND)
  local lvl = R.compile(def)
  return def, lvl
end

function M.graph(def, lvl, filter)
  local G = assert(SV.explore(lvl, 3000000, filter), "cap")
  local good = SV.goodSet(G)
  return G, good
end

function M.xy(lvl, c) return R.xy(lvl, c) end

-- конфигурация деталей одной строкой: tag(x,y)F
function M.cfg(lvl, st)
  local t = {}
  for q, p in ipairs(lvl.pieces) do
    if p.movable then
      if st.pos[q] == 0 then t[#t + 1] = p.tag .. "(смыт)"
      else local x, y = R.xy(lvl, st.pos[q]); t[#t + 1] = string.format("%s(%d,%d)%s", p.tag, x, y, st.fixed[q] and "F" or "") end
    end
  end
  return table.concat(t, " ")
end

-- доска (в вывод инструмента)
function M.show(lvl, st, label)
  local SYM = { source = "S", fixture = "F", stub = "T", pipe = "=", fitting = "b", porcelain = "P" }
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y - 1) * lvl.W + x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  for q, p in ipairs(lvl.pieces) do
    if st.pos[q] ~= 0 then
      local x, y = R.xy(lvl, st.pos[q])
      local ch = SYM[p.kind]
      if p.what == "tee" then ch = "t" elseif p.what == "plug" then ch = "z" elseif p.what == "nipple" then ch = "n" end
      if p.movable and st.fixed[q] then ch = ch:upper() end
      rows[y][x] = ch
    end
  end
  if not st.dead then for i, c in ipairs(st.body) do local x, y = R.xy(lvl, c); rows[y][x] = (i == #st.body) and "H" or ((i == 1) and "f" or "o") end end
  local out = { label or "" }
  for y = 1, lvl.H do out[#out + 1] = table.concat(rows[y]) end
  return table.concat(out, "\n")
end

-- применить строку ходов вида "fu fl Hr Hd ..." (f — ноги, H — голова; u r d l)
function M.apply(lvl, st, seq, verbose)
  local D = { u = 1, r = 2, d = 3, l = 4 }
  local n = 0
  for tok in seq:gmatch("%S+") do
    local w = tok:sub(1, 1) == "H" and "head" or "heel"
    local d = assert(D[tok:sub(2, 2)], "bad move " .. tok)
    local ns, why = R.move(lvl, st, w, d)
    n = n + 1
    if not ns then return st, n, "отказ: " .. tok .. " (" .. tostring(why) .. ")" end
    st = ns
    if verbose then print(M.show(lvl, st, n .. " " .. tok .. "  " .. M.cfg(lvl, st))) end
    if st.dead then return st, n, "смыт" end
  end
  return st, n
end

-- умная обезьяна с произвольной разметкой lost[i] (как check.lua); возвращает и распределение массы первого входа
function M.monkey(G, good, lost, T)
  local ES, E, flag = G.eStart.p, G.edges.p, G.flag
  local p, ok = { [1] = 1.0 }, 0
  for _ = 1, T do
    local np = {}
    for i, pr in pairs(p) do
      local cand = {}
      for e = ES[i - 1], ES[i] - 1 do
        local j = E[e]
        if flag[j] == 1 then cand[#cand + 1] = j elseif flag[j] ~= 2 and not lost[j] then cand[#cand + 1] = j end
      end
      if #cand == 0 then np[i] = (np[i] or 0) + pr else
        local share = pr / #cand
        for _, j in ipairs(cand) do if flag[j] == 1 then ok = ok + share else np[j] = (np[j] or 0) + share end end
      end
    end
    p = np
  end
  return 100 * (1 - (1 - ok) ^ (1000 / T)), p
end

-- все ворота по заданной разметке lost[i]: строка как в check.lua
function M.gates(lvl, G, good, lost, label)
  local n, ES, E, flag = G.n, G.eStart.p, G.edges.p, G.flag
  local live, vis, hid, washed = 0, 0, 0, 0
  local hidden = {}
  for i = 1, n do
    if flag[i] == 2 then washed = washed + 1
    elseif good[i] == 1 then live = live + 1
    elseif lost[i] then vis = vis + 1 else hid = hid + 1; hidden[i] = true end
  end
  local opt = G.depth[G.firstWin]
  local smart = M.monkey(G, good, lost, 5 * opt)
  local path, x = {}, G.firstWin
  while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
  table.insert(path, 1, 1)
  local function depthFrom(j)
    local d, q, h, maxd = { [j] = 0 }, { j }, 1, 0
    while h <= #q do
      local u = q[h]; h = h + 1
      for e = ES[u - 1], ES[u] - 1 do
        local v = E[e]
        if hidden[v] and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; q[#q + 1] = v end
      end
    end
    return maxd
  end
  local deepAt, maxDeep = {}, 0
  for k = 1, #path - 1 do
    local s = path[k]
    for e = ES[s - 1], ES[s] - 1 do
      local j = E[e]
      if hidden[j] then local d = depthFrom(j); if d > (deepAt[k - 1] or -1) then deepAt[k - 1] = d end; if d > maxDeep then maxDeep = d end end
    end
  end
  local dl = {}
  for k = 0, #path - 2 do if deepAt[k] then dl[#dl + 1] = k .. ":" .. deepAt[k] end end
  print(string.format("[%s] ходов %d | состояний %d (живых %d, видимых потерь %d, скрытых %d, смыт %d)", label, opt, n, live, vis, hid, washed))
  print(string.format("[%s] СКРЫТЫХ %.0f %% (≥40) | УМНАЯ ОБЕЗЬЯНА %.2f %% (≤0.2) | ГЛУБИНА %d (≥8) у пути [%s]",
    label, 100 * hid / math.max(1, hid + live), smart, maxDeep, table.concat(dl, " ")))
  return { live = live, vis = vis, hid = hid, smart = smart, maxDeep = maxDeep, hidden = hidden, path = path }
end

M.R, M.SV, M.V = R, SV, V
return M
