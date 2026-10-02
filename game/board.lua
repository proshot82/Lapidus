-- Рендер поля в утверждённом арте (фаза 3). Фон квартиры (кладка, комната, сливы, стояк, крючья) —
-- готовая картинка assets/gfx/lvlNN; приборы, фаянс, голова и ноги — спрайты, нарисованные при клетке
-- 240 px; гофру движок рисует сам по сглаженному пути через центры клеток: светотень, рёбра (их
-- густота показывает растяжение), бегущая вода.
local R = require("core.rules")
local lg = love.graphics
local Board = {}
Board.__index = Board

local CR = 240
local DIRV = { { 0, -1 }, { 1, 0 }, { 0, 1 }, { -1, 0 } }
local DNAME = { "up", "right", "down", "left" }
local ANG = { -math.pi / 2, 0, math.pi / 2, math.pi }
local COL = {
  ol = { 0.169, 0.129, 0.094 }, hose = { 0.965, 0.953, 0.918 }, hoseMid = { 0.871, 0.843, 0.769 },
  hoseSh = { 0.698, 0.659, 0.557 }, rib = { 0.612, 0.573, 0.478 }, water = { 0.18, 0.77, 0.945 },
  waterLt = { 0.74, 0.95, 1.0 }, glow = { 0.5, 0.886, 1.0 }, dark = { 0.08, 0.06, 0.05 },
  wall = { 0.55, 0.52, 0.47 }, room = { 0.36, 0.48, 0.42 }, pit = { 0.05, 0.1, 0.13 },
}
Board.COL, Board.CR = COL, CR
local IMG = {}
function Board.img(name)
  local v = IMG[name]
  if v == nil then
    v = false
    for _, ext in ipairs({ ".png", ".jpg" }) do
      local p = "assets/gfx/" .. name .. ext
      if love.filesystem.getInfo(p) then
        -- в браузере (WebGL 1) mipmaps для текстур не степени двойки недоступны
        local mip = love.system.getOS() ~= "Web"
        v = lg.newImage(p, { mipmaps = mip })
        if mip then v:setMipmapFilter("linear") end
        break
      end
    end
    IMG[name] = v
  end
  return v or nil
end
local img = Board.img
local function setc(c, a) lg.setColor(c[1], c[2], c[3], a or 1) end
local function spr(name, x, y, k, r, sx)
  local im = img(name)
  if im then lg.draw(im, x, y, r or 0, k * (sx or 1), k, CR, CR) end
end
Board.spr = spr

function Board.new(lvl, def)
  local self = setmetatable({ lvl = lvl, def = def }, Board)
  local cs = math.min(120, math.floor((1920 - 2 * 290) / lvl.W), math.floor(1080 / lvl.H)) -- по бокам резерв 290 px под HUD; та же формула в art/gen.py geom и art/gen2.py frame
  self.cs, self.k = cs, cs / CR
  self.x0 = math.floor((1920 - lvl.W * cs) / 2)
  self.y0 = math.floor((1080 - lvl.H * cs) / 2)
  self.bg = img(string.format("lvl%02d", def and def.id or 0))
  return self
end

function Board:center(i)
  local x, y = R.xy(self.lvl, i)
  return self.x0 + (x - 0.5) * self.cs, self.y0 + (y - 0.5) * self.cs
end

function Board:cellAt(vx, vy)
  local x = math.floor((vx - self.x0) / self.cs) + 1
  local y = math.floor((vy - self.y0) / self.cs) + 1
  if x < 1 or y < 1 or x > self.lvl.W or y > self.lvl.H then return nil end
  return R.idx(self.lvl, x, y)
end

function Board:drawBackground()
  lg.setColor(1, 1, 1)
  if self.bg then lg.draw(self.bg, 0, 0) return end
  local lvl, cs = self.lvl, self.cs
  setc(COL.dark); lg.rectangle("fill", 0, 0, 1920, 1080)
  for i = 1, lvl.N do
    local x, y = R.xy(lvl, i)
    local c = lvl.cell[i]
    setc(c == R.WALL and COL.wall or (c == R.PIT and COL.pit or COL.room))
    lg.rectangle("fill", self.x0 + (x - 1) * cs, self.y0 + (y - 1) * cs, cs, cs)
  end
end

-- Сталь для «окаменевших» деталей: тот же сдвиг цвета, что фильтр steel в art/screens2.py.
local STEEL
local function steelShader()
  if STEEL == nil then
    local ok, sh = pcall(lg.newShader, [[
      extern number amt;
      vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
        vec4 c = Texel(tex, tc) * color;
        float g = dot(c.rgb, vec3(0.30, 0.59, 0.11));
        vec3 st = vec3(g * 0.78 + 0.02, g * 0.82 + 0.03, g * 0.90 + 0.06);
        return vec4(mix(c.rgb, st, amt), c.a);
      }]])
    STEEL = ok and sh or false
  end
  return STEEL or nil
end

-- stone: 0 — подвижная латунь (с тенью на полу), 1 — прикручена к сети, сталь без тени (§8).
function Board:drawPiece(p, cx, cy, wet, alpha, stone)
  local k = self.k
  stone = stone or 0
  if p.kind == "fitting" and stone < 1 then
    lg.setColor(0, 0, 0, 0.28 * (1 - stone) * (alpha or 1))
    lg.ellipse("fill", cx + 0.04 * self.cs, cy + 0.44 * self.cs, 0.40 * self.cs, 0.07 * self.cs)
  end
  lg.setColor(1, 1, 1, alpha or 1)
  local sh = p.kind == "fitting" and stone > 0 and steelShader()
  if sh then sh:send("amt", stone); lg.setShader(sh) end
  if p.kind == "fixture" then
    local pd
    for d = 1, 4 do if p.ports[d] then pd = d end end
    -- прибор вписан в 0.80×0.92 клетки (art/export.py fit_box) и отодвинут от входа: подводка на свободном краю клетки
    local ox, oy = 0, 0
    if pd then ox, oy = -DIRV[pd][1] * 0.07 * self.cs, -DIRV[pd][2] * 0.07 * self.cs end
    spr(string.format("fx_%s_%s", p.what or "bath", wet and "wet" or "dry"), cx + ox, cy + oy, k, 0, pd == 2 and -1 or 1)
    if pd then spr(img("port_" .. p.ports[pd] .. "_fx") and ("port_" .. p.ports[pd] .. "_fx") or ("port_" .. p.ports[pd] .. "_fixed"), cx, cy, k, ANG[pd]) end
  elseif p.kind == "porcelain" then
    spr("porcelain", cx, cy, k)
  elseif p.kind == "fitting" then
    local sig = ""
    for d = 1, 4 do if p.ports[d] then sig = sig .. ("urdl"):sub(d, d) .. p.ports[d] end end
    if img("fit_" .. sig) then spr("fit_" .. sig, cx, cy, k)
    else for d = 1, 4 do if p.ports[d] then spr("port_" .. p.ports[d], cx, cy, k, ANG[d]) end end end
  end
  if sh then lg.setShader() end
end

-- Сглаживание изломов пути (радиус — полклетки), как в генераторе арта.
local function smooth(pts, r)
  local out = { pts[1][1], pts[1][2] }
  for i = 2, #pts - 1 do
    local p0, p1, p2 = pts[i - 1], pts[i], pts[i + 1]
    local d1x, d1y, d2x, d2y = p1[1] - p0[1], p1[2] - p0[2], p2[1] - p1[1], p2[2] - p1[2]
    local l1, l2 = math.sqrt(d1x * d1x + d1y * d1y), math.sqrt(d2x * d2x + d2y * d2y)
    if l1 > 1e-3 and l2 > 1e-3 then
      d1x, d1y, d2x, d2y = d1x / l1, d1y / l1, d2x / l2, d2y / l2
      if math.abs(d1x * d2y - d1y * d2x) > 0.01 then
        local rr = math.min(r, l1 * 0.5, l2 * 0.5)
        local ax, ay, bx, by = p1[1] - d1x * rr, p1[2] - d1y * rr, p1[1] + d2x * rr, p1[2] + d2y * rr
        out[#out + 1], out[#out + 2] = ax, ay
        for s = 1, 10 do
          local t = s / 10
          local u = 1 - t
          out[#out + 1] = u * u * ax + 2 * u * t * p1[1] + t * t * bx
          out[#out + 1] = u * u * ay + 2 * u * t * p1[2] + t * t * by
        end
      else
        out[#out + 1], out[#out + 2] = p1[1], p1[2]
      end
    end
  end
  out[#out + 1], out[#out + 2] = pts[#pts][1], pts[#pts][2]
  return out
end

local function cumul(flat)
  local L = { 0 }
  for i = 3, #flat, 2 do
    local dx, dy = flat[i] - flat[i - 2], flat[i + 1] - flat[i - 1]
    L[#L + 1] = L[#L] + math.sqrt(dx * dx + dy * dy)
  end
  return L
end

local function subpath(flat, L, s0, s1)
  local out = {}
  for j = 1, #L - 1 do
    local a, b = L[j], L[j + 1]
    if b >= s0 and a <= s1 and b > a then
      local ax, ay, bx, by = flat[2 * j - 1], flat[2 * j], flat[2 * j + 1], flat[2 * j + 2]
      local t0, t1 = math.max(0, (s0 - a) / (b - a)), math.min(1, (s1 - a) / (b - a))
      if #out == 0 then out[1], out[2] = ax + (bx - ax) * t0, ay + (by - ay) * t0 end
      out[#out + 1], out[#out + 2] = ax + (bx - ax) * t1, ay + (by - ay) * t1
    end
  end
  return out
end

local function dirOf(p, q)
  local dx, dy = p[1] - q[1], p[2] - q[2]
  if math.abs(dx) >= math.abs(dy) then return dx >= 0 and 2 or 4 end
  return dy >= 0 and 3 or 1
end

-- pts — точки от ног к голове (центры клеток, конец может быть в пути); n — длина тела в клетках.
function Board:drawLapidus(pts, n, active, wet, screwedHead, screwedFeet, dead, t)
  local cs, k, np = self.cs, self.k, #pts
  if np < 2 then return end
  local a = dead and 0.45 or 1
  t = t or 0
  local head, feet = pts[np], pts[1]
  local hd, fd = dirOf(head, pts[np - 1]), dirOf(feet, pts[2])
  if active and not dead then
    local e = (active == "head") and head or feet
    for i = 1, 6 do setc(COL.glow, 0.05); lg.circle("fill", e[1], e[2], cs * (0.3 + i * 0.08)) end
    setc(COL.water, 0.85); lg.setLineWidth(cs * 0.035)
    for j = 0, 7 do
      local a0 = t * 1.5 + j * math.pi / 4
      lg.arc("line", "open", e[1], e[2], cs * 0.64, a0, a0 + math.pi / 7)
    end
  end
  local flat = smooth(pts, cs * 0.5)
  local w = 0.56 * cs
  lg.setLineJoin("bevel")
  local function stroke(c, width, dx, dy, al)
    lg.push(); lg.translate(dx or 0, dy or 0)
    setc(c, (al or 1) * a); lg.setLineWidth(width); lg.line(flat)
    lg.circle("fill", flat[1], flat[2], width / 2); lg.circle("fill", flat[#flat - 1], flat[#flat], width / 2)
    lg.pop()
  end
  stroke(COL.dark, w + 0.09 * cs, 0.05 * cs, 0.08 * cs, 0.35)
  stroke(COL.ol, w + 0.09 * cs)
  stroke(COL.hoseSh, w)
  stroke(COL.hoseMid, w * 0.80, -0.035 * cs, -0.05 * cs)
  stroke(COL.hose, w * 0.46, -0.06 * cs, -0.10 * cs)
  local L = cumul(flat)
  local per = 4 + 4 * (self.lvl.Lmax - n) / math.max(1, self.lvl.Lmax - self.lvl.Lmin)
  local hw, o = w * 0.46, 0.035 * cs
  for s = cs / per * 0.5, L[#L], cs / per do
    local seg = subpath(flat, L, s, s + 1)
    if #seg >= 4 then
      local px, py = seg[1], seg[2]
      local tx, ty = seg[#seg - 1] - px, seg[#seg] - py
      local tl = math.sqrt(tx * tx + ty * ty)
      if tl > 1e-6 then tx, ty = tx / tl, ty / tl end
      local nearHead = (px - head[1]) ^ 2 + (py - head[2]) ^ 2 < (0.45 * cs) ^ 2
      local nearFeet = (px - feet[1]) ^ 2 + (py - feet[2]) ^ 2 < (0.40 * cs) ^ 2
      if not nearHead and not nearFeet then
        local ax, ay, bx, by = px + ty * hw, py - tx * hw, px - ty * hw, py + tx * hw
        local mx, my = px + tx * 0.07 * cs, py + ty * 0.07 * cs
        setc(COL.rib, a); lg.setLineWidth(cs * 0.03)
        lg.line(ax, ay, (ax + mx) / 2 + tx * 0.02 * cs, (ay + my) / 2 + ty * 0.02 * cs, mx, my, (bx + mx) / 2 + tx * 0.02 * cs, (by + my) / 2 + ty * 0.02 * cs, bx, by)
        lg.setColor(1, 1, 1, 0.7 * a); lg.setLineWidth(cs * 0.016)
        lg.line(ax - tx * o, ay - ty * o, mx - tx * o, my - ty * o, bx - tx * o, by - ty * o)
      end
    end
  end
  if wet then
    local total, period = L[#L], cs * 0.32
    local ph = (t * cs * 1.4) % period
    for _, layer in ipairs({ { COL.water, 0.12, 0.22, 0 }, { COL.waterLt, 0.035, 0.10, 0.05 } }) do
      lg.setLineWidth(cs * layer[2])
      for s = -period + ph + cs * layer[4], total, period do
        local seg = subpath(flat, L, math.max(0, s), math.min(total, s + cs * layer[3]))
        if #seg >= 4 then setc(layer[1], a); lg.line(seg) end
      end
    end
  end
  lg.setColor(1, 1, 1, a)
  spr(string.format("feet_%s_%s", DNAME[fd], active == "heel" and "on" or "off"), feet[1], feet[2], k)
  spr(string.format("head_%s_%s", DNAME[hd], active == "head" and "on" or "off"), head[1], head[2], k)
  if screwedFeet then spr("fluff", feet[1] + DIRV[fd][1] * 0.47 * cs, feet[2] + DIRV[fd][2] * 0.47 * cs, k, ANG[fd]) end
  if screwedHead then spr("fluff", head[1] + DIRV[hd][1] * 0.47 * cs, head[2] + DIRV[hd][2] * 0.47 * cs, k, ANG[hd]) end
end

function Board:drawWater(status, jets, pressure, t)
  local cs = self.cs
  t = t or 0
  if pressure > 0 then
    for _, j in ipairs(jets or {}) do
      local dx, dy = DIRV[j.dir][1], DIRV[j.dir][2]
      local sx, sy = self:center(j.cell)
      sx, sy = sx + dx * cs * 0.5, sy + dy * cs * 0.5
      local len = #j.cells * cs
      local ex, ey = sx + dx * len, sy + dy * len
      local px, py = -dy, dx -- поперёк струи
      -- тело струи: колышется по ширине, светлый блик вдоль оси, капли бегут от стояка к шапке
      local wob = 1 + 0.08 * math.sin(t * 9)
      setc(COL.water, 0.88); lg.setLineWidth(cs * 0.26 * wob); lg.line(sx, sy, ex, ey)
      lg.setColor(1, 1, 1, 0.45); lg.setLineWidth(cs * 0.06)
      lg.line(sx + px * cs * 0.05, sy + py * cs * 0.05, ex + px * cs * 0.05, ey + py * cs * 0.05)
      for q = 0, 3 do
        local f = (t * 2.2 + q / 4) % 1
        local side = (q % 2 == 0) and 1 or -1
        lg.setColor(1, 1, 1, 0.8 * (1 - f))
        lg.circle("fill", sx + dx * len * f + px * side * cs * 0.07, sy + dy * len * f + py * side * cs * 0.07, cs * 0.035)
      end
      -- пенная шапка на конце струи
      for q = 0, 4 do
        local a = q / 5 * math.pi * 2 + t * 1.3
        local pr = cs * (0.10 + 0.025 * math.sin(t * 7 + q * 1.7))
        lg.setColor(1, 1, 1, 0.92)
        lg.circle("fill", ex + math.cos(a) * cs * 0.09 + dx * cs * 0.04, ey + math.sin(a) * cs * 0.06 + dy * cs * 0.04, pr)
      end
    end
  else
    -- Без напора — маленький фонтанчик из открытой резьбы (решение Lao 03.10; напора в игре больше нет, путать не с чем):
    -- вверх — столбик с короной, вбок — дуга-брызгалка, вниз — струйка с всплеском. Всё в пределах соседней клетки.
    for n, lk in ipairs(status.leaks or {}) do
      local dx, dy = DIRV[lk.dir][1], DIRV[lk.dir][2]
      local cx, cy = self:center(lk.cell)
      local ex, ey = cx + dx * cs * 0.47, cy + dy * cs * 0.47
      local lvl, floorY = self.lvl, nil
      local tc = lvl.nb[lk.cell][lk.dir]
      if tc ~= 0 then
        local below = lvl.nb[tc][3]
        if below == 0 or lvl.cell[below] == R.WALL then local _, ty = self:center(tc); floorY = ty + cs * 0.5 end
      end
      self:fountain(ex, ey, dx, dy, t, n, floorY)
    end
  end
end

-- Фонтанчик: струя по кривой pts (обводка, вода, бегущие блики) и капли с её конца.
function Board:jet(pts, t, seed, w)
  local cs = self.cs
  if #pts < 4 then return end
  setc(COL.ol, 0.55); lg.setLineWidth(cs * (w + 0.03)); lg.line(pts)
  setc(COL.water); lg.setLineWidth(cs * w); lg.line(pts)
  local L = cumul(pts)
  local total, period = L[#L], cs * 0.22
  local ph = (t * cs * 1.6 + seed * 7) % period
  setc(COL.waterLt, 0.95); lg.setLineWidth(cs * w * 0.35)
  for s0 = ph - period, total, period do
    local seg = subpath(pts, L, math.max(0, s0), math.min(total, s0 + cs * 0.07))
    if #seg >= 4 then lg.line(seg) end
  end
end

-- капля-«слёзка» хвостиком вверх (как в мультяшных фонтанах): обводка, вода, блик
local function drop(x, y, r, a)
  local tri = { x - r * 0.86, y - r * 0.5, x + r * 0.86, y - r * 0.5, x, y - r * 2.4 }
  setc(COL.ol, 0.85 * a); lg.circle("fill", x, y, r + 1.8)
  lg.polygon("fill", tri[1] - 1.8, tri[2], tri[3] + 1.8, tri[4], tri[5], tri[6] - 2.2)
  setc(COL.water, a); lg.circle("fill", x, y, r); lg.polygon("fill", tri)
  lg.setColor(1, 1, 1, 0.8 * a); lg.circle("fill", x - r * 0.35, y - r * 0.25, r * 0.28)
end

-- «шапка» фонтана: лепестки-языки воды из одной точки; боковые изгибаются вниз (зонтик). Сначала все обводки,
-- потом тёмная вода (тени между языками), потом светлая, потом блики — чтобы языки читались по отдельности.
local DEEP = { 0.10, 0.55, 0.80 }
local function crown(cx, cy, list, cs)
  for pass = 1, 4 do
    for _, pt in ipairs(list) do
      local ang, len, wid = pt[1], pt[2], pt[3]
      local droop = math.cos(ang) * 0.9            -- вбок смотрящие языки загибаются вниз
      lg.push(); lg.translate(cx, cy); lg.rotate(ang)
      local function seg(pad, shrink)
        lg.ellipse("fill", len * 0.30, 0, len * 0.30 + pad, wid * shrink + pad)
        lg.push(); lg.translate(len * 0.55, 0); lg.rotate(droop * (ang < 0 and 1 or -1) * (math.cos(ang) > 0 and 1 or -1))
        lg.ellipse("fill", len * 0.22, 0, len * 0.26 + pad, wid * 0.85 * shrink + pad)
        lg.pop()
      end
      if pass == 1 then setc(COL.ol, 0.9); seg(3, 1)
      elseif pass == 2 then lg.setColor(DEEP[1], DEEP[2], DEEP[3]); seg(0, 1)
      elseif pass == 3 then setc(COL.water); seg(-1.5, 0.62)
      elseif pt[4] then setc(COL.waterLt, 0.85); lg.ellipse("fill", len * 0.32, -wid * 0.25, len * 0.16, wid * 0.18) end
      lg.pop()
    end
  end
end

function Board:fountain(x, y, dx, dy, t, seed, floorY)
  local cs = self.cs
  local wob = 0.03 * math.sin(t * 13 + seed * 2.1)
  if dy < 0 then
    -- фонтанчик (по образцу Lao 03.10): спрайт fountain (art/parts.py) — столбик и пышная шапка; «дышит» по высоте,
    -- с краёв шапки падают капли-слёзки
    local h = cs * 0.52
    local cyc = y - h
    local im = img("fountain")
    if im then
      local k = self.k
      lg.setColor(1, 1, 1)
      lg.draw(im, x, y, 0, k * (1 + 0.03 * math.sin(t * 7 + seed)), k * (1 + 0.06 * math.sin(t * 9 + seed * 1.7)), CR, CR)
    end
    for k = 0, 3 do
      local f = (t * 1.1 + k / 4 + seed * 0.37) % 1
      local side = (k % 2 == 0) and 1 or -1
      local px = x + side * cs * (0.33 + 0.05 * (k % 3))
      drop(px, cyc + cs * 0.20 + f * (h - cs * 0.16), cs * 0.032, math.min(1, (1 - f) * 2.5))
    end
  elseif dy == 0 then
    -- брызгалка вбок: струя выходит чуть вверх и дугой падает в пределах клетки
    local pts, ex, ey = {}, x, y
    for i = 0, 14 do
      local s = i / 14
      local px, py = x + dx * cs * 0.75 * s * (1 + wob), y + cs * (-0.42 * s + 0.80 * s * s)
      if floorY and py > floorY - cs * 0.03 then break end
      pts[#pts + 1], pts[#pts + 2] = px, py
      ex, ey = px, py
    end
    self:jet(pts, t, seed, 0.085)
    for k = 0, 3 do
      local f = (t * 2.1 + k / 4 + seed * 0.29) % 1
      local px, py = ex + dx * cs * 0.12 * f + (k - 1.5) * cs * 0.05 * f, ey - cs * 0.10 * f + cs * 0.30 * f * f
      if floorY and py > floorY - cs * 0.03 then py = floorY - cs * 0.03 end
      drop(px, py, cs * 0.028, 1 - f)
    end
  else
    -- вниз: тонкая струйка до пола (или на клетку) и всплеск-корона
    local y2 = math.min(floorY and floorY - cs * 0.02 or y + cs, y + cs)
    self:jet({ x, y, x + cs * 0.01 * math.sin(t * 15), y2 }, t, seed, 0.045)
    for k = 0, 3 do
      local f = (t * 2.4 + k / 4 + seed * 0.31) % 1
      local side = (k % 2 == 0) and 1 or -1
      drop(x + side * cs * 0.16 * f, y2 - cs * (0.16 * f - 0.2 * f * f), cs * 0.025, 1 - f)
    end
  end
end

-- Струйка без напора: короткий «носик» из выхода по дуге вниз (не дальше клетки), дальше капли гаснут на лету.
-- Вода без напора ничего не толкает и клеток не занимает — поэтому и нарисована локально, а не до пола.
function Board:stream(x, y, vx, t, seed, floorY)
  local cs = self.cs
  seed = seed or 0
  local pts, wob = {}, 0.04 * math.sin(t * 11 + seed)
  for i = 0, 14 do
    local sp = i / 14 * 0.62
    local py = y + cs * 1.6 * sp * sp
    if floorY and py > floorY - cs * 0.04 then break end
    pts[#pts + 1] = x + vx * cs * sp * (1 + wob)
    pts[#pts + 1] = py
  end
  if #pts < 4 then return end
  local tx, ty = pts[#pts - 1], pts[#pts]
  setc(COL.ol, 0.85); lg.setLineWidth(cs * 0.16); lg.line(pts)
  setc(COL.water); lg.setLineWidth(cs * 0.11); lg.line(pts)
  local L = cumul(pts)
  local total = L[#L]
  local period = cs * 0.3
  local ph = (t * cs * 1.8 + seed * 11) % period
  setc(COL.waterLt, 0.95); lg.setLineWidth(cs * 0.035)
  for s0 = ph - period, total, period do
    local seg = subpath(pts, L, math.max(0, s0), math.min(total, s0 + cs * 0.1))
    if #seg >= 4 then lg.line(seg) end
  end
  -- капли срываются с конца струйки и гаснут в пределах клетки
  local vx1 = vx * 0.55
  for k = 0, 3 do
    local f = (t * 1.9 + k / 4 + seed * 0.29) % 1
    local r = cs * (0.05 - 0.02 * f)
    local px, py = tx + vx1 * cs * 0.25 * f, ty + cs * 0.75 * f * f + cs * 0.05
    if floorY and py > floorY - r then py = floorY - r; px = tx + vx1 * cs * 0.25 * f + (k - 1.5) * cs * 0.12 * f end
    setc(COL.ol, 0.8 * (1 - f)); lg.circle("fill", px, py, r + 2)
    setc(COL.water, 1 - f); lg.circle("fill", px, py, r)
  end
end
return Board
