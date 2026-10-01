-- build/l9v/lib.lua — общий код слепого скептика кв. 9 (g7): граф, разметка, расстояния, классы.
-- Печать решений запрещена: здесь только метрики. Кадры не печатаются.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local M = {}
M.R, M.SV, M.V = R, SV, V

function M.load(path, opts)
  opts = opts or {}
  local def = type(path) == "table" and path or dofile(path)
  local lvl = R.compile(def)
  local G = SV.explore(lvl, opts.cap or 3000000, opts.filter)
  assert(G, "CAP")
  local good = SV.goodSet(G)
  local VL
  if G.firstWin then
    V.POCKET = opts.pocket or 4
    VL = V.compute(lvl, G, def, good)
    V.POCKET = 4
  end
  local S = { def = def, lvl = lvl, G = G, good = good, VL = VL, n = G.n,
    ES = G.eStart.p, E = G.edges.p, flag = G.flag, sts = {} }
  return setmetatable(S, { __index = M })
end

function M:st(i) local s = self.sts[i]; if not s then s = R.decode(self.lvl, self.G.keys[i]); self.sts[i] = s end; return s end
function M:live(i) return self.good[i] == 1 end
function M:hid(i, lostArr) lostArr = lostArr or self.VL.newbie; return self.flag[i] == 0 and self.good[i] ~= 1 and not lostArr[i] end
function M:vis(i, lostArr) lostArr = lostArr or self.VL.newbie; return self.flag[i] == 0 and self.good[i] ~= 1 and lostArr[i] end

-- обратные рёбра и расстояние до победы
function M:rev()
  if self._rs then return self._rs, self._rv end
  local n, ES, E = self.n, self.ES, self.E
  local cnt = {}
  for i = 1, n + 1 do cnt[i] = 0 end
  for i = 1, n do for e = ES[i-1], ES[i]-1 do local j = E[e]; cnt[j] = cnt[j] + 1 end end
  local rs, s = {}, 1
  for i = 1, n do rs[i] = s; s = s + cnt[i] end
  rs[n+1] = s
  local fill, rv = {}, {}
  for i = 1, n do fill[i] = rs[i] end
  for i = 1, n do for e = ES[i-1], ES[i]-1 do local j = E[e]; rv[fill[j]] = i; fill[j] = fill[j] + 1 end end
  self._rs, self._rv = rs, rv
  return rs, rv
end
function M:distWin()
  if self._dw then return self._dw end
  local rs, rv = self:rev()
  local dw, q, h = {}, {}, 1
  for i = 1, self.n do if self.flag[i] == 1 then dw[i] = 0; q[#q+1] = i end end
  while h <= #q do local j = q[h]; h = h + 1
    for k = rs[j], rs[j+1]-1 do local i = rv[k]; if dw[i] == nil then dw[i] = dw[j] + 1; q[#q+1] = i end end end
  self._dw = dw
  return dw
end
function M:opt() return self.G.depth[self.G.firstWin] end
-- состояния на каких-либо кратчайших путях
function M:onShortest()
  if self._sp then return self._sp end
  local dw, opt, sp = self:distWin(), self:opt(), {}
  for i = 1, self.n do if dw[i] and self.G.depth[i] + dw[i] == opt then sp[i] = true end end
  self._sp = sp
  return sp
end
-- область скрытых от состояния j (BFS по скрытым): глубина и размер
function M:region(j, lostArr)
  local d, q, h, maxd = { [j] = 0 }, { j }, 1, 0
  while h <= #q do local u = q[h]; h = h + 1
    for e = self.ES[u-1], self.ES[u]-1 do local v = self.E[e]
      if self:hid(v, lostArr) and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; q[#q+1] = v end end end
  return maxd, #q, d
end
-- мин. ходов от j до видимого (по разметке lostArr), двигаясь по скрытым
function M:reveal(j, lostArr)
  lostArr = lostArr or self.VL.newbie
  if not self:hid(j, lostArr) then return 0 end
  local d, q, h = { [j] = 0 }, { j }, 1
  while h <= #q do local u = q[h]; h = h + 1
    for e = self.ES[u-1], self.ES[u]-1 do local v = self.E[e]
      if self.flag[v] == 0 and self.good[v] ~= 1 and lostArr[v] then return d[u] + 1 end
      if self:hid(v, lostArr) and d[v] == nil then d[v] = d[u] + 1; q[#q+1] = v end end end
  return nil
end

-- описание детали: тег(x,y)F/свободна; смыта
function M:tagOf(q) local p = self.lvl.pieces[q]; return p.tag or p.what or p.kind end
function M:cfg(s)
  local t = {}
  for q, p in ipairs(self.lvl.pieces) do if p.movable then
    if s.pos[q] == 0 then t[#t+1] = p.tag .. "=смыт" else
      local x, y = R.xy(self.lvl, s.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag, x, y, s.fixed[q] and "F" or "") end end end
  return table.concat(t, " ")
end
-- только закреплённые подвижные детали (класс «окаменения»)
function M:fixedSig(s)
  local t = {}
  for q, p in ipairs(self.lvl.pieces) do if p.movable and s.pos[q] ~= 0 and s.fixed[q] then
    local x, y = R.xy(self.lvl, s.pos[q]); t[#t+1] = string.format("%s@%d,%d", p.tag, x, y) end end
  return #t > 0 and table.concat(t, " ") or "ничего не закреплено"
end
function M:wet(s)
  local w = R.water(self.lvl, s)
  for q, p in ipairs(self.lvl.pieces) do if p.kind == "pipe" and w.wet[q] then return true end end
  return false
end
function M:free() self.SV.freeGraph(self.G); require("ffi").C.free(self.good) end
return M
