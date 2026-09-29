-- Сцена квартиры: заявка жильца, ходы с анимацией по трассе ядра, отмена, рестарт, горячая линия
-- (суть → «Я в тупике?» → мастер), «смыло», победа: вода → немая сцена → акт → хрущёвка.
local R = require("core.rules")
local Search = require("core.search")
local Board = require("game.board")
local Levels = require("game.levels")
local SaveM = require("game.save")
local UI = require("game.ui")
local lg = love.graphics

local Play = {}
Play.__index = Play
local STEP_MOVE, STEP_SETTLE = 0.10, 0.07
local DIRKEY = { up = 1, w = 1, right = 2, d = 2, down = 3, s = 3, left = 4, a = 4 }
local BUTTONS = { { id = "undo" }, { id = "restart" }, { id = "hint" }, { id = "menu" } }
local INK, CREAM, BLUE, GOLD = UI.INK, UI.CREAM, UI.BLUE, UI.GOLD
local setc = UI.setc
local WASHED = {
  { "Лапидус ушёл в канализацию.", "Не навсегда. Отмена — %s." },
  { "Смыло.", "Горячая линия соболезнует в порядке очереди. Отмена — %s." },
  { "Ушёл в трубу.", "Акт о затоплении пишем на вас. Отмена — %s." },
  { "Лапидуса смыло.", "Жильцы снизу пока не в курсе. Отмена — %s." },
  { "Пропал в трапе.", "Вернуть можно: %s." },
  { "Канализация приняла.", "Отмена — %s. Это не больно." },
}
local HOT = { "1 · Суть", "2 · Я в тупике?", "3 · Вызвать мастера" }

function Play.new(app, index)
  local self = setmetatable({ app = app, t = 0, solutions = Levels.solutions(), washN = 0 }, Play)
  self:start(index)
  return self
end

function Play:start(index)
  self.index = index
  self.def = self.app.levels[index]
  self.lvl = R.compile(self.def)
  self.state = R.newState(self.lvl)
  self.history, self.moves, self.active = {}, 0, "head"
  self.anim, self.won, self.toast, self.winPhase = nil, false, nil, nil
  self.search, self.master, self.hotline = nil, nil, nil
  self.calls, self.masterUsed = 0, false
  self.board = Board.new(self.lvl, self.def)
  self.request = not (self.app.autoplay or (self.app.shot and not self.app.demo))
  self.app.save.current = index
  SaveM.write(self.app.save)
  self:refresh()
  if self.app.autoplay then self:callMaster(true) end
  local demo = self.app.demo
  if demo == "hotline" then self.request = false; self:openHotline()
  elseif demo == "hotline2" then self.request = false; self:hotlineTier(2)
  elseif demo == "master" then self.request = false; self:say(((self.def.texts or {}).hints or {})[3] or "Мастер выехал.", 60)
  elseif demo == "act" then self.request = false; self.won, self.winPhase, self.moves = true, "act", 21
  elseif demo == "scene" then self.request = false; self.won, self.winPhase = true, "scene"
  elseif demo == "washed" then self.request = false; self.state = R.clone(self.state); self.state.dead = true
  elseif demo == "late" then -- снимок поля перед последним ходом решения (проверка «окаменевших» деталей); только в выводе
    self.request = false
    local sol = self.solutions[string.format("%02d", self.index)]
    local mv = sol and sol.moves or {}
    for k = 1, #mv - 1 do
      local w, d = mv[k]:match("^(%a+):(%a+)$")
      local ns = R.move(self.lvl, self.state, w, R.DIRINDEX[d])
      if ns then self.state = ns end
    end
    self.active = "head"; self:refresh()
  elseif demo == "toast" then self.request = false; self:say("Голова по фаянсу скользит: толкай ногами.", 60) end
end

function Play:refresh()
  local old = self.status
  self.status = R.status(self.lvl, self.state)
  self.jets = R.jets(self.lvl, self.state)
  local A = self.app.audio
  if old and not self.quiet and not self.state.dead and ((self.status.headQ and self.status.headQ ~= old.headQ) or (self.status.heelQ and self.status.heelQ ~= old.heelQ)) then
    A.play("screw", 0.8)
  end
  A.setJet((self.lvl.R > 0 and #self.jets > 0) and math.min(1, 0.4 + 0.15 * #self.jets) or 0)
end

function Play:say(text, dur) self.toast = { text = text, t = dur or 3 } end
function Play:keyName() local d = self.app.lastInput; return d == "pad" and "B" or (d == "touch" and "кнопка ↶" or "Z") end

-- Звук сегмента анимации (§9): ход, толчок, свинчивание, «окаменение», падение (звук — на приземлении), смыв.
local MOVE_SFX = { stretch = "stretch", slide = "stretch", compress = "compress", push_stretch = "push", push_slide = "push" }
local function changed(a, b)
  if #a.body ~= #b.body then return true end
  for i = 1, #a.body do if a.body[i] ~= b.body[i] then return true end end
  for q = 1, #a.pos do if a.pos[q] ~= b.pos[q] then return true end end
  return false
end
function Play:segSound(seg, nxt)
  local A = self.app.audio
  if MOVE_SFX[seg.kind] then
    A.play(MOVE_SFX[seg.kind], 0.7, 0.95 + 0.1 * math.random())
    if seg.kind:sub(1, 4) == "push" then A.play("stretch", 0.4) end
  elseif seg.kind == "wash" then A.play("wash", 0.9)
  elseif seg.kind == "settle" then
    local f0, f1, merged = 0, 0, false
    for q = 1, #seg.to.pos do
      if seg.from.fixed[q] then f0 = f0 + 1 end
      if seg.to.fixed[q] then f1 = f1 + 1 end
      if seg.from.asm[q] ~= seg.to.asm[q] then merged = true end
    end
    if f1 > f0 then A.play("screw", 0.8); A.play("stone", 0.6)
    elseif merged then A.play("screw", 0.8) end
    local fall = changed(seg.from, seg.to)
    if fall and not (nxt and nxt.kind == "settle" and changed(nxt.from, nxt.to)) then A.play("land", 0.8) end
  end
end

function Play:finishAnim()
  if self.anim then self.anim = nil; self:afterMove() end
end

function Play:tryMove(dir)
  self:finishAnim()
  if self.won then return end
  if self.state.dead then self:say("Смыло. Сначала отмените ход — " .. self:keyName() .. ".") return end
  local trace = {}
  local ns, kind = R.move(self.lvl, self.state, self.active, dir, trace)
  if not ns then
    local why = { soap = "Голова по фаянсу скользит: толкай ногами.", taut = "Натянут: второй конец прикручен.",
                  short = "Короче уже не сжаться.", blocked = "Не сдвинуть: упирается.", fixed = "Закреплено намертво." }
    if why[kind] then self:say(why[kind], 2) end
    local snd = { soap = "squeak", taut = "taut", blocked = "blocked", fixed = "stone", short = "compress" }
    if snd[kind] then self.app.audio.play(snd[kind], kind == "fixed" and 0.4 or 0.7) end
    return
  end
  table.insert(self.history, { state = self.state, moves = self.moves, active = self.active })
  local segs, prev = {}, self.state
  for _, f in ipairs(trace) do
    segs[#segs + 1] = { from = prev, to = f.state, kind = f.kind, which = f.which,
                        dur = (f.kind == "settle" or f.kind == "wash") and STEP_SETTLE or STEP_MOVE }
    prev = f.state
  end
  if self.app.autoplay then for _, s in ipairs(segs) do s.dur = s.dur * 0.3 end end
  self.state = ns
  self.moves = self.moves + 1
  self.anim = { segs = segs, i = 1, t = 0 }
  if segs[1] then self:segSound(segs[1], segs[2]) end
end

function Play:afterMove()
  self:refresh()
  if self.state.dead then
    self.washN = self.washN + 1
  elseif self.status.win then
    self.won, self.winPhase, self.winT = true, "water", 0
    self.app.audio.play("win", 0.9)
    self.hotline = nil
    local key = tostring(self.index)
    self.app.save.solved[key] = true
    local best = self.app.save.best[key]
    if not best or self.moves < best then self.app.save.best[key] = self.moves end
    SaveM.write(self.app.save)
  end
end

function Play:undoMove()
  self:finishAnim()
  local h = table.remove(self.history)
  if not h then return end
  self.state, self.moves, self.active = h.state, h.moves, h.active
  self.won, self.master, self.winPhase = false, nil, nil
  self.quiet = true; self:refresh(); self.quiet = false
  self.app.audio.play("compress", 0.35, 1.3)
end

function Play:restart()
  self:finishAnim()
  table.insert(self.history, { state = self.state, moves = self.moves, active = self.active })
  self.state, self.moves, self.won, self.master, self.winPhase = R.newState(self.lvl), 0, false, nil, nil
  self.quiet = true; self:refresh(); self.quiet = false
  self.app.audio.play("wash", 0.35, 1.4)
end

function Play:optimum()
  local s = self.solutions[string.format("%02d", self.index)]
  return s and s.moves and #s.moves or nil
end

function Play:callMaster(fromStart)
  local s = self.solutions[string.format("%02d", self.index)]
  if not fromStart and self.search and self.search.result == "found" then
    self.master = { moves = self.search.path, i = 1, delay = 0.3 }
  elseif s and s.moves then
    if not fromStart then self:restart() end
    local list = {}
    for k, name in ipairs(s.moves) do list[k] = R.parseMove(name) end
    self.master = { moves = list, i = 1, delay = 0.3 }
  end
end

-- Горячая линия: 1 — ключевая мысль уровня, 2 — честный поиск «Я в тупике?», 3 — мастер.
function Play:openHotline()
  self.hotline = { tier = 1 }
  self.calls = self.calls + 1
end

function Play:hotlineTier(tier)
  local hints = (self.def.texts and self.def.texts.hints) or {}
  if not self.hotline then self:openHotline() end
  if tier == 1 then
    self.hotline.tier = 1
  elseif tier == 2 then
    self.hotline.tier, self.hotline.status = 2, hints[2] or "Проверяем, есть ли у вас выход."
    self.search = Search.new(self.lvl, self.state, 200000)
  else
    self.hotline = nil
    self:callMaster(false)
    self.masterUsed = true
    self:say(hints[3] or "Мастер выехал.", 3)
  end
end

function Play:update(dt)
  self.t = self.t + dt
  local A = self.app.audio
  local h = self.hotline ~= nil
  if h ~= (self.holdOn or false) then self.holdOn = h; A.hold(h) end
  if not self.anim and self.lvl.R == 0 and self.status and #(self.status.leaks or {}) > 0 and not self.request then
    self.dripT = (self.dripT or 0.5) - dt
    if self.dripT <= 0 then self.dripT = 0.45 + math.random() * 0.8; A.play("drip", 0.3, 0.85 + 0.3 * math.random()) end
  end
  -- «окаменение» (§8): деталь, прикрученная к сети, за ~0,3 с переходит из латуни в сталь; отмена — обратно
  local fx = self.anim and self.anim.segs[self.anim.i].from.fixed or self.state.fixed
  self.stone = self.stone or {}
  for q = 1, #self.lvl.pieces do
    local goal = fx[q] and 1 or 0
    local cur = self.stone[q] or goal
    self.stone[q] = goal > cur and math.min(goal, cur + dt * 3.5) or math.max(goal, cur - dt * 3.5)
  end
  if self.toast then self.toast.t = self.toast.t - dt; if self.toast.t <= 0 then self.toast = nil end end
  if self.anim then
    local a = self.anim
    a.t = a.t + dt
    while self.anim and a.t >= a.segs[a.i].dur do
      a.t = a.t - a.segs[a.i].dur
      a.i = a.i + 1
      if a.i > #a.segs then self.anim = nil; self:afterMove()
      else self:segSound(a.segs[a.i], a.segs[a.i + 1]) end
    end
  end
  if self.search and not self.search.done then
    if Search.step(self.search, 1500) then
      local r = self.search.result
      local text = (r == "found" and "Нет, вы не в тупике: выход есть.") or (r == "exhausted" and "Да, тупик. Отменяйте ходы или начните заново.")
        or "Не знаю: вариантов слишком много."
      if self.hotline then self.hotline.status = text else self:say(text, 5) end
    end
  end
  if self.winPhase and not self.app.autoplay then
    self.winT = (self.winT or 0) + dt
    if self.winPhase == "water" and self.winT > 1.4 then self.winPhase, self.winT = "scene", 0
    elseif self.winPhase == "scene" and self.winT > 4.5 then self.winPhase, self.winT = "act", 0 end
  end
  if self.master and not self.anim then
    local m = self.master
    m.delay = m.delay - dt
    if m.delay <= 0 then
      if m.i > #m.moves or self.won then
        self.master = nil
        if self.app.autoplay then self:autoNext() end
      else
        local mv = R.MOVES[m.moves[m.i]]
        self.active = mv.which
        self:tryMove(mv.dir)
        m.i = m.i + 1
        m.delay = self.app.autoplay and 0.02 or 0.25
      end
    end
  end
end

function Play:autoNext()
  local ok = self.won
  print(string.format("AUTOPLAY level %02d %s moves=%d", self.index, ok and "WIN" or "FAIL", self.moves))
  if self.index < #self.app.levels then self:start(self.index + 1) else love.event.quit(ok and 0 or 1) end
end

function Play:view()
  local st, pts, piecesView = self.state, {}, {}
  local B = self.board
  if self.anim then
    local seg = self.anim.segs[self.anim.i]
    local u = math.min(1, self.anim.t / seg.dur)
    u = u * u * (3 - 2 * u)
    local fb, tb = seg.from.body, seg.to.body
    local function lp(a, b) local ax, ay = B:center(a); local bx, by = B:center(b); return { ax + (bx - ax) * u, ay + (by - ay) * u } end
    local k = seg.kind
    if (k == "stretch" or k == "push_stretch") and seg.which == "head" then
      for i = 1, #fb do pts[i] = { B:center(fb[i]) } end
      pts[#pts + 1] = lp(fb[#fb], tb[#tb])
    elseif (k == "stretch" or k == "push_stretch") then
      pts[1] = lp(fb[1], tb[1])
      for i = 1, #fb do pts[i + 1] = { B:center(fb[i]) } end
    elseif k == "compress" and seg.which == "head" then
      for i = 1, #fb - 1 do pts[i] = { B:center(fb[i]) } end
      pts[#pts + 1] = lp(fb[#fb], fb[#fb - 1])
    elseif k == "compress" then
      pts[1] = lp(fb[1], fb[2])
      for i = 2, #fb do pts[i] = { B:center(fb[i]) } end
    else
      for i = 1, #tb do pts[i] = lp(fb[i] or tb[i], tb[i]) end
    end
    for q = 1, #self.lvl.pieces do
      local a, b = seg.from.pos[q], seg.to.pos[q]
      if a ~= 0 and b ~= 0 then piecesView[q] = { lp(a, b), 1 }
      elseif a ~= 0 then local c = { B:center(a) }; c[2] = c[2] + u * B.cs; piecesView[q] = { c, 1 - u } end
    end
  else
    for i = 1, #st.body do pts[i] = { B:center(st.body[i]) } end
    for q = 1, #self.lvl.pieces do if st.pos[q] ~= 0 then piecesView[q] = { { B:center(st.pos[q]) }, 1 } end end
  end
  return pts, piecesView
end

-- ---------------------------------------------------------------- рисование

function Play:drawHud()
  local F, B = self.app.font, self.board
  local px = B.x0 / 2
  lg.setColor(1, 1, 1)
  local im = Board.img("hud_plate")
  if im then lg.draw(im, px - 130, 22) end
  lg.setFont(F.num); lg.printf(tostring(self.def.flat or self.index), px - 100, 112 - F.num:getHeight() / 2, 200, "center")
  lg.push(); lg.translate(px, 254); lg.rotate(-0.05)
  local tag = Board.img("hud_tag")
  lg.setColor(1, 1, 1); if tag then lg.draw(tag, -160, -62) end
  lg.setFont(F.hand); setc(BLUE); lg.printf(self.def.name, -150, -F.hand:getHeight() / 2 + 2, 300, "center")
  lg.pop()
  UI.plate(px - 140, 326, 280, 150)
  local s = string.format("%03d", math.min(self.moves, 999))
  for i = 1, 3 do
    local bx = px - 105 + (i - 1) * 74
    setc(CREAM); lg.rectangle("fill", bx, 346, 62, 78, 6)
    lg.setColor(0.169, 0.129, 0.094); lg.setLineWidth(2); lg.rectangle("line", bx, 346, 62, 78, 6)
    lg.setColor(0, 0, 0, 0.25); lg.setLineWidth(1.5); lg.line(bx + 2, 385, bx + 60, 385)
    lg.setFont(F.digit); lg.setColor(0.106, 0.106, 0.106); lg.printf(s:sub(i, i), bx, 385 - F.digit:getHeight() / 2, 62, "center")
  end
  lg.setFont(F.s); setc(CREAM); lg.printf("Х О Д Ы", px - 140, 436, 280, "center")
  UI.plate(px - 140, 502, 280, 124)
  lg.setColor(1, 1, 1)
  Board.spr(self.active == "head" and "head_right_on" or "feet_right_on", px - 64, 572, 76 / Board.CR)
  lg.setFont(F.xs); lg.setColor(0.75, 0.71, 0.635); lg.printf(self.active == "head" and "ходит" or "ходят", px - 16, 530, 130, "center")
  lg.setFont(F.b); setc(CREAM); lg.printf(self.active == "head" and "голова" or "ноги", px - 16, 566, 130, "center")
  for i, b in ipairs(BUTTONS) do
    b.cx, b.cy = 1920 - B.x0 / 2, 170 + (i - 1) * 150
    local bi = Board.img("btn_" .. b.id)
    lg.setColor(1, 1, 1); if bi then lg.draw(bi, b.cx - 72, b.cy - 72) end
  end
end

function Play:drawRequest()
  local F = self.app.font
  lg.setColor(0, 0, 0, 0.72); lg.rectangle("fill", 0, 0, 1920, 1080)
  lg.setFont(F.b); setc(CREAM); lg.printf("З А Я В К А", 0, 212, 1920, "center")
  -- вкладыш к паспорту: карточка нового правила (texts.card) справа от записки, записка сдвигается влево
  local card = self.def.texts and self.def.texts.card and Board.img(self.def.texts.card)
  if card then
    local z = math.min(1.1, 540 / card:getHeight()) -- высокий вкладыш (card07, две полосы) ужимается по высоте
    lg.push(); lg.translate(1330, 540); lg.rotate(0.03)
    lg.setColor(0, 0, 0, 0.3); lg.rectangle("fill", -card:getWidth() * z / 2 + 10, -card:getHeight() * z / 2 + 14, card:getWidth() * z, card:getHeight() * z, 14)
    lg.setColor(1, 1, 1); lg.draw(card, 0, 0, 0, z, z, card:getWidth() / 2, card:getHeight() / 2)
    lg.pop()
    local top = 540 - card:getHeight() * z / 2
    if top > 270 then lg.setFont(F.s); setc(GOLD); lg.printf("вкладыш к паспорту изделия", 1330 - 340, top - 58, 680, "center") end
  end
  lg.push(); lg.translate(card and 600 or 960, 520); lg.rotate(-0.035)
  local note = Board.img("note")
  lg.setColor(1, 1, 1); if note then lg.draw(note, -370, -235) end
  lg.setFont(F.handL); setc(BLUE)
  local text = (self.def.texts and self.def.texts.request) or ""
  lg.printf(text, -250, -150, 560, "left")
  lg.setFont(F.hand); lg.printf("— жилец кв. " .. tostring(self.def.flat or self.index), -330, 150, 640, "right")
  lg.pop()
  lg.setFont(F.m); setc(GOLD); lg.printf("любая клавиша или касание — к работе", 0, 822, 1920, "center")
end

function Play:drawHotline()
  local F = self.app.font
  local h = self.hotline
  local hints = (self.def.texts and self.def.texts.hints) or {}
  local x0, y0, w, hh = 330, 660, 1260, 390
  UI.plate(x0, y0, w, hh)
  local hx, hy = x0 + 80, y0 + 100
  lg.setColor(0.82, 0.635, 0.22); lg.setLineWidth(18); lg.arc("line", "open", hx + 10, hy, 44, math.pi * 0.62, math.pi * 1.38)
  lg.rectangle("fill", hx - 44, hy - 62, 36, 26, 9); lg.rectangle("fill", hx - 44, hy + 36, 36, 26, 9)
  lg.setFont(F.b); setc(GOLD); lg.print("Горячая линия управляющей компании", x0 + 150, y0 + 30)
  lg.setFont(F.xs); lg.setColor(0.62, 0.69, 0.72); if not UI.isMobile() then lg.printf("Esc — отбой", x0, y0 + 36, w - 36, "right") end
  local text = (h.tier == 1) and (hints[1] or "Подумайте, каким концом начинать.") or (h.status or "")
  lg.setFont(F.m); setc(CREAM); lg.printf(text, x0 + 150, y0 + 96, w - 190)
  h.rects = {}
  for i, lab in ipairs(HOT) do
    local bx, by = x0 + 150 + (i - 1) * 354, y0 + hh - 96
    h.rects[i] = { bx, by, 330, 64 }
    if i == h.tier then UI.brass(bx, by, 330, 64) else UI.plate(bx, by, 330, 64) end
    lg.setFont(F.b)
    if i == h.tier then lg.setColor(0.169, 0.129, 0.094) else setc(CREAM) end
    lg.printf(lab, bx, by + 32 - F.b:getHeight() / 2, 330, "center")
  end
end

function Play:drawWashed()
  local F = self.app.font
  local L = WASHED[(self.washN - 1) % #WASHED + 1] or WASHED[1]
  lg.setColor(0.047, 0.055, 0.063, 0.84); lg.rectangle("fill", 0, 420, 1920, 210)
  lg.setFont(F.l); setc(CREAM); lg.printf(L[1], 0, 452, 1920, "center")
  lg.setFont(F.m); setc(GOLD); lg.printf(string.format(L[2], self:keyName()), 0, 552, 1920, "center")
end

function Play:drawScene()
  lg.setColor(0.09, 0.106, 0.118); lg.rectangle("fill", 0, 0, 1920, 1080)
  local im = Board.img("scene" .. tostring(self.index))
  if im then
    local z = 1.45 + 0.05 * math.min(1, (self.winT or 0) / 4.5)
    lg.setColor(1, 1, 1); lg.draw(im, 960, 540, 0, z, z, im:getWidth() / 2, im:getHeight() / 2)
  end
end

function Play:drawAct()
  local F = self.app.font
  lg.setColor(0, 0, 0, 0.6); lg.rectangle("fill", 0, 0, 1920, 1080)
  lg.push(); lg.translate(960, 540); lg.rotate(-0.02)
  local paper = Board.img("act_paper")
  lg.setColor(1, 1, 1); if paper then lg.draw(paper, -420, -510) end
  setc(INK); lg.setFont(F.l); lg.printf("АКТ № " .. tostring(self.def.flat or self.index), -400, -440, 800, "center")
  lg.setFont(F.m); lg.printf("выполненных работ", -400, -372, 800, "center")
  lg.setLineWidth(2.5); lg.line(-340, -318, 340, -318)
  local opt = self:optimum()
  local what = { bath = "ванна", toilet = "унитаз", sink = "мойка", washer = "стиральная машина", dryer = "полотенцесушитель", heater = "газовая колонка" }
  local fx
  for _, o in ipairs(self.def.objects) do if o.kind == "fixture" then fx = what[o.what] or o.what end end
  local rows = {
    { "Адрес:", string.format("подъезд 1, квартира %d", self.def.flat or self.index) },
    { "Работы:", string.format("вода к прибору «%s»", fx or "прибор") },
    { "Исполнитель:", "гофра самоходная «Лапидус»" },
    { "Ходов:", opt and string.format("%d при норме %d", self.moves, opt) or tostring(self.moves) },
    { "Горячая линия:", self.calls > 0 and string.format("звонили: %d", self.calls) or "не вызывалась" },
    { "Мастер:", self.masterUsed and "вызывался" or "не вызывался" },
  }
  for i, r in ipairs(rows) do
    local y = -270 + (i - 1) * 66
    -- подпись и значение ужимаются целиком (без сплющивания), чтобы не залезать друг на друга и за край бланка
    lg.setFont(F.b); setc(INK)
    local ls = math.min(1, 206 / F.b:getWidth(r[1]))
    lg.print(r[1], -340, y - 34 + (1 - ls) * 26, 0, ls, ls)
    lg.setFont(F.hand); setc(BLUE)
    local sx = math.min(1, 458 / F.hand:getWidth(r[2]))
    lg.print(r[2], -120, y - 40 + (1 - sx) * 30, 0, sx, sx)
    lg.setColor(0.6, 0.64, 0.72); lg.setLineWidth(1.5); lg.line(-124, y + 12, 340, y + 12)
  end
  setc(INK); lg.setLineWidth(3); lg.rectangle("line", -340, 160, 330, 150, 10)
  lg.setFont(F.b); lg.printf("РАЗРЯД", -340, 176, 330, "center")
  local g = UI.grade(self.moves, opt)
  lg.setFont(F.gradeF); lg.setColor(0.78, 0.24, 0.18); lg.printf(g and (g .. "-й") or "—", -340, 206, 330, "center")
  local st = Board.img("stamp")
  lg.setColor(1, 1, 1); if st then lg.draw(st, 200, 230, -0.24, 0.8, 0.8, 160, 160) end
  lg.pop()
  lg.setFont(F.m); setc(CREAM); lg.printf("Enter или касание — в подъезд", 0, 1026, 1920, "center")
end

function Play:draw()
  local F, B = self.app.font, self.board
  if self.winPhase == "scene" then return self:drawScene() end
  B:drawBackground()
  local pts, pv = self:view()
  local wet = self.status.wet or {}
  for q, p in ipairs(self.lvl.pieces) do
    local v = pv[q]
    if v then B:drawPiece(p, v[1][1], v[1][2], (not self.anim) and wet[q], v[2], self.stone and self.stone[q] or (self.state.fixed[q] and 1 or 0)) end
  end
  if not self.anim then B:drawWater(self.status, self.jets, self.lvl.R, self.t) end
  local sh, sf = false, false
  if not self.anim and not self.state.dead then
    local occ = {}
    for q = 1, #self.state.pos do if self.state.pos[q] ~= 0 then occ[self.state.pos[q]] = q end end
    sh = R.endScrew(self.lvl, self.state, occ, "head") ~= nil
    sf = R.endScrew(self.lvl, self.state, occ, "heel") ~= nil
  end
  if not self.state.dead or self.anim then
    B:drawLapidus(pts, #self.state.body, self.active, (not self.anim) and self.status.lapWet, sh, sf, false, self.t)
  end
  self:drawHud()
  if self.state.dead and not self.anim then self:drawWashed() end
  if self.toast then
    lg.setFont(F.m)
    local tw = math.min(1400, F.m:getWidth(self.toast.text) + 90)
    local _, lines = F.m:getWrap(self.toast.text, tw - 60)
    local th = #lines * F.m:getHeight() + 40
    UI.plate(960 - tw / 2, 1040 - th, tw, th)
    setc(CREAM); lg.printf(self.toast.text, 960 - tw / 2 + 30, 1040 - th + 20, tw - 60, "center")
  end
  if self.hotline then self:drawHotline() end
  if self.request then self:drawRequest() end
  if self.winPhase == "act" then self:drawAct() end
end

-- ---------------------------------------------------------------- ввод

function Play:leave() self.app.go("select", self.index) end

function Play:advanceWin()
  if self.winPhase == "water" then self.winPhase, self.winT = "scene", 0
  elseif self.winPhase == "scene" then self.winPhase, self.winT = "act", 0
  elseif self.winPhase == "act" then self:leave() end
end

function Play:action(a, arg)
  if a == "move" then self:tryMove(arg)
  elseif a == "switch" then self.active = (self.active == "head") and "heel" or "head"; self.app.audio.play("click", 0.5, self.active == "head" and 1.2 or 0.85)
  elseif a == "undo" then self:undoMove()
  elseif a == "restart" then self:restart()
  elseif a == "hint" then if self.hotline then self.hotline = nil else self:openHotline() end
  elseif a == "menu" then self:leave()
  elseif a == "next" then if self.index < #self.app.levels then self:start(self.index + 1) end
  elseif a == "prev" then if self.index > 1 then self:start(self.index - 1) end end
end

function Play:key(k)
  if self.request then self.request = false return end
  if self.winPhase then
    if k == "z" or k == "backspace" then return self:undoMove() end
    return self:advanceWin()
  end
  if self.hotline then
    if k == "1" or k == "2" or k == "3" then return self:hotlineTier(tonumber(k)) end
    if k == "escape" or k == "h" then self.hotline = nil return end
  end
  if DIRKEY[k] then self.hotline = nil; self:action("move", DIRKEY[k])
  elseif k == "space" or k == "tab" then self:action("switch")
  elseif k == "z" or k == "backspace" then self:action("undo")
  elseif k == "r" then self:action("restart")
  elseif k == "h" then self:action("hint")
  elseif k == "pagedown" then self:action("next")
  elseif k == "pageup" then self:action("prev")
  elseif k == "escape" then self:action("menu") end
end

function Play:pad(b)
  if self.request then self.request = false return end
  if self.winPhase then if b == "b" then return self:undoMove() end return self:advanceWin() end
  local map = { dpup = 1, dpright = 2, dpdown = 3, dpleft = 4 }
  if map[b] then self.hotline = nil; self:action("move", map[b])
  elseif b == "a" then if self.hotline then self:hotlineTier(math.min(3, self.hotline.tier + 1)) else self:action("switch") end
  elseif b == "b" then if self.hotline then self.hotline = nil else self:action("undo") end
  elseif b == "x" then self:action("hint")
  elseif b == "y" then self:action("restart")
  elseif b == "start" or b == "back" then self:action("menu")
  elseif b == "rightshoulder" then self:action("next")
  elseif b == "leftshoulder" then self:action("prev") end
end

function Play:pointer(kind, x, y)
  if kind == "press" then self.press = { x, y } return end
  local p = self.press
  self.press = nil
  if not p then return end
  if self.request then self.request = false return end
  if self.winPhase then return self:advanceWin() end
  if self.hotline then
    for i, r in ipairs(self.hotline.rects or {}) do if UI.inside(x, y, r) then return self:hotlineTier(i) end end
    if not UI.inside(x, y, { 330, 660, 1260, 390 }) then self.hotline = nil end
    return
  end
  local dx, dy = x - p[1], y - p[2]
  if math.abs(dx) + math.abs(dy) > 50 then
    if math.abs(dx) > math.abs(dy) then self:action("move", dx > 0 and 2 or 4) else self:action("move", dy > 0 and 3 or 1) end
    return
  end
  for _, b in ipairs(BUTTONS) do
    if b.cx and (x - b.cx) ^ 2 + (y - b.cy) ^ 2 <= 64 * 64 then return self:action(b.id) end
  end
  local c = self.board:cellAt(x, y)
  local body = self.state.body
  if c == body[#body] then self.active = "head" elseif c == body[1] then self.active = "heel" end
end

return Play
