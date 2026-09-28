-- verify_vis.lua — скептик кв. 7 (28.09): варианты видимого проигрыша для L7A (модуль; подключают verify_*.lua).
-- Решений здесь нет. Все варианты проверяются verify_gates.lua: живых среди помеченных должно быть 0.
--   narrow  — авторский узкий (L7A.lua);
--   wideA   — авторский «самый широкий» (L7Aw.lua);
--   V1      — wideA + «деталь в углу кармана»: клетка справа внизу кармана — угол (стена справа и снизу),
--             деталь оттуда не сдвинуть никогда (толкать некому ни влево, ни вверх; струя угольника жмёт её
--             в ту же стену), а в единственной выигрышной сборке через эту клетку проходит сам Лапидус
--             (ноги затыкают выход угольника сбоку, шея — в углу; при длине 5 путь один);
--   V2      — V1 + «угольник заперт в шахте»: переходник уже в ванне, угольник висит в шахте под ним —
--             струя держит его снизу, переходник сверху, слева стена, справа толкать некому: до основания
--             фонтана он не дойдёт никогда (та же «зажата навсегда», что у автора, только внутри струи);
--   V3      — V2 + «муфта в шахте при пустой ванне» (спорно: нужно предвидеть, что струя загонит её
--             в резьбу ванны раньше, чем туда упадёт переходник; для оценки запаса).
local M = {}

local function tags(lvl) local Q = {}; for q, p in ipairs(lvl.pieces) do if p.tag then Q[p.tag] = q end end; return Q end
local function srcCell(lvl) for _, p in ipairs(lvl.pieces) do if p.source then return p.start end end end

function M.narrow(lvl, st)
  local R = require("core.rules")
  local piece = {}
  for q = 1, #st.pos do if st.pos[q] ~= 0 then piece[st.pos[q]] = q end end
  local function solid(c) if c == 0 or lvl.cell[c] == 1 then return true end local r = piece[c]; return r and st.fixed[r] end
  local jet = {}
  for _, j in ipairs(R.jets(lvl, st)) do for _, c in ipairs(j.cells) do jet[c] = true end end
  local src = srcCell(lvl)
  local first = lvl.nb[src][1]
  for q, p in ipairs(lvl.pieces) do
    if (p.tag == "adp" or p.tag == "elb") and st.pos[q] ~= 0 then
      local c = st.pos[q]
      if st.fixed[q] then
        if p.tag == "elb" and c ~= first then return true end
        if p.tag == "adp" then
          local ok = false
          for _, b in ipairs(lvl.pieces) do if b.fixture and (lvl.nb[b.start][2] == c or lvl.nb[b.start][4] == c) then ok = true end end
          if not ok then return true end
        end
      elseif not jet[c] and solid(lvl.nb[c][3]) then
        local boxed = true
        for d = 1, 4 do
          local fwd, back = lvl.nb[c][d], lvl.nb[c][({ 3, 4, 1, 2 })[d]]
          if not solid(fwd) and not solid(back) then boxed = false end
        end
        if boxed then return true end
      end
    end
  end
  return false
end

function M.wideA(lvl, st)
  if M.narrow(lvl, st) then return true end
  local W = lvl.W
  local Q = tags(lvl)
  local src = srcCell(lvl)
  if st.fixed[Q.cpl] then return true end
  if st.pos[Q.adp] ~= 0 and not st.fixed[Q.adp] and (st.pos[Q.adp] - 1) % W > (src - 1) % W then return true end
  if st.pos[Q.cpl] ~= 0 and st.pos[Q.adp] ~= 0 and st.asm[Q.cpl] == st.asm[Q.adp] then return true end
  if st.fixed[Q.elb] and not st.fixed[Q.adp] then
    if st.pos[Q.adp] == 0 or (st.pos[Q.adp] - 1) % W ~= (src - 1) % W then return true end
  end
  return false
end

-- угол кармана: единственная клетка поля, где стена справа и снизу и через которую идёт выигрышная сборка
local function corner(lvl) return (6 - 1) * lvl.W + 8 end -- (8,6)

function M.cornerJunk(lvl, st)
  local c = corner(lvl)
  for q, p in ipairs(lvl.pieces) do if p.movable and st.pos[q] == c then return true end end
  return false
end

function M.elbPinned(lvl, st)
  local Q = tags(lvl)
  local src = srcCell(lvl)
  local e = st.pos[Q.elb]
  if e == 0 or st.fixed[Q.elb] or not st.fixed[Q.adp] then return false end
  local x = (e - 1) % lvl.W
  return x == (src - 1) % lvl.W and e > st.pos[Q.adp] and e < src
end

function M.cplInShaft(lvl, st)
  local Q = tags(lvl)
  local src = srcCell(lvl)
  local c = st.pos[Q.cpl]
  if c == 0 or st.fixed[Q.cpl] or st.fixed[Q.adp] then return false end
  local x, y = (c - 1) % lvl.W, math.floor((c - 1) / lvl.W)
  local sy = math.floor((src - 1) / lvl.W)
  -- ниже уровня входа ванны (ванна — единственный прибор), в столбе стояка
  local bath
  for _, p in ipairs(lvl.pieces) do if p.fixture then bath = p.start end end
  local by = math.floor((bath - 1) / lvl.W)
  return x == (src - 1) % lvl.W and y > by and y < sy
end

function M.V1(lvl, st) return M.wideA(lvl, st) or M.cornerJunk(lvl, st) end
function M.V2(lvl, st) return M.V1(lvl, st) or M.elbPinned(lvl, st) end
function M.V3(lvl, st) return M.V2(lvl, st) or M.cplInShaft(lvl, st) end
-- без спорного правила автора «фонтан заглушён раньше переходника» (это само «ага», а не взгляд)
function M.V2noCap(lvl, st)
  if M.narrow(lvl, st) or M.cornerJunk(lvl, st) or M.elbPinned(lvl, st) then return true end
  local W = lvl.W
  local Q = tags(lvl)
  local src = srcCell(lvl)
  if st.fixed[Q.cpl] then return true end
  if st.pos[Q.adp] ~= 0 and not st.fixed[Q.adp] and (st.pos[Q.adp] - 1) % W > (src - 1) % W then return true end
  if st.pos[Q.cpl] ~= 0 and st.pos[Q.adp] ~= 0 and st.asm[Q.cpl] == st.asm[Q.adp] then return true end
  return false
end
-- только бесспорное поверх узкого автора: угол кармана и запертый угольник (муфту в ванне не помечает)
function M.narrowPlus(lvl, st) return M.narrow(lvl, st) or M.cornerJunk(lvl, st) or M.elbPinned(lvl, st) end

return M
