-- tools/gen_audio.lua — синтез всех звуков и музыки «Лапидуса» кодом (DESIGN §9): WAV во временную папку, OGG — в assets/sfx и assets/music.
--   luajit tools/gen_audio.lua            — всё
--   luajit tools/gen_audio.lua sfx|music  — только эффекты или только музыку
-- Лупы музыки бесшовные: хвосты нот после конца такта заворачиваются в начало. Случайность — с фиксированным зерном.
local ffi = require("ffi")
local SR = 44100
local TAU = 2 * math.pi
local sin, exp, floor, abs, min, max = math.sin, math.exp, math.floor, math.abs, math.min, math.max
local TMP = os.getenv("TMPDIR") or "/tmp"
local ROOT = arg[0]:match("^(.*)/tools/") or "."

-- ------------------------------------------------------------ буфер и вывод
local function buf(sec) local n = floor(sec * SR); local b = ffi.new("double[?]", n); return { n = n, d = b } end
local seed = 12345
local function rnd() seed = (seed * 1103515245 + 12345) % 2147483648; return seed / 2147483648 end
local function noise() return rnd() * 2 - 1 end

local function writeWav(path, b, peak)
  local n = b.n
  local m = 1e-9
  for i = 0, n - 1 do m = max(m, abs(b.d[i])) end
  local g = (peak or 0.89) / m
  local f = assert(io.open(path, "wb"))
  local function u32(v) f:write(string.char(v % 256, floor(v / 256) % 256, floor(v / 65536) % 256, floor(v / 16777216) % 256)) end
  local function u16(v) f:write(string.char(v % 256, floor(v / 256) % 256)) end
  f:write("RIFF"); u32(36 + n * 2); f:write("WAVEfmt "); u32(16); u16(1); u16(1); u32(SR); u32(SR * 2); u16(2); u16(16)
  f:write("data"); u32(n * 2)
  local out = ffi.new("int16_t[?]", n)
  for i = 0, n - 1 do
    local v = b.d[i] * g
    v = max(-1, min(1, v))
    out[i] = floor(v * 32767 + 0.5)
  end
  f:write(ffi.string(out, n * 2)); f:close()
end

local function toOgg(name, b, dir, peak)
  local wav = TMP .. "/lap_" .. name .. ".wav"
  writeWav(wav, b, peak)
  os.execute(string.format('mkdir -p "%s/assets/%s"', ROOT, dir))
  local cmd = string.format('ffmpeg -loglevel error -y -i "%s" -c:a libvorbis -q:a 4 "%s/assets/%s/%s.ogg"', wav, ROOT, dir, name)
  assert(os.execute(cmd) == 0 or true)
  os.remove(wav)
  print(dir .. "/" .. name .. ".ogg", string.format("%.2f с", b.n / SR))
end

-- ------------------------------------------------------------ фильтры
local function lp1(fc) local a = 1 - exp(-TAU * fc / SR); local y = 0; return function(x) y = y + a * (x - y); return y end end
local function hp1(fc) local l = lp1(fc); return function(x) return x - l(x) end end
-- биквад (RBJ): "lp" | "hp" | "bp"
local function biquad(kind, fc, q)
  local w = TAU * fc / SR
  local cs, al = math.cos(w), sin(w) / (2 * (q or 0.707))
  local b0, b1, b2
  if kind == "lp" then b0, b1, b2 = (1 - cs) / 2, 1 - cs, (1 - cs) / 2
  elseif kind == "hp" then b0, b1, b2 = (1 + cs) / 2, -(1 + cs), (1 + cs) / 2
  else b0, b1, b2 = al, 0, -al end
  local a0, a1, a2 = 1 + al, -2 * cs, 1 - al
  b0, b1, b2, a1, a2 = b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0
  local x1, x2, y1, y2 = 0, 0, 0, 0
  return function(x)
    local y = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
    x2, x1, y2, y1 = x1, x, y1, y
    return y
  end
end

-- добавить функцию f(t) в буфер с позиции t0 (сек), длительностью dur; wrap — заворачивать хвост в начало (лупы)
local function add(b, t0, dur, f, wrap)
  local i0 = floor(t0 * SR)
  local n = floor(dur * SR)
  for k = 0, n - 1 do
    local i = i0 + k
    if wrap then i = i % b.n end
    if i >= 0 and i < b.n then b.d[i] = b.d[i] + f(k / SR) end
  end
end

local function midi(m) return 440 * 2 ^ ((m - 69) / 12) end
local function env(t, a, d) if t < a then return t / a end return exp(-(t - a) / d) end

-- ------------------------------------------------------------ эффекты
local SFX = {}

-- гармошка (растяжение/сжатие): язычковый тон с вибрато + шум меха; up — тон вверх
local function bellows(up)
  local b = buf(0.24)
  local bp = biquad("bp", 1400, 0.8)
  local ph1, ph2 = 0, 0
  add(b, 0, 0.24, function(t)
    local u = t / 0.24
    local f = (up and (330 + 110 * u) or (440 - 110 * u)) * (1 + 0.012 * sin(TAU * 6 * t))
    ph1 = ph1 + f / SR; ph2 = ph2 + f * 1.005 / SR
    local saw = ((ph1 % 1) * 2 - 1) + ((ph2 % 1) * 2 - 1)
    local e = math.min(1, t / 0.03) * math.min(1, (0.24 - t) / 0.08)
    return (saw * 0.25 + bp(noise()) * 0.6) * e
  end)
  local l = lp1(2600)
  for i = 0, b.n - 1 do b.d[i] = l(b.d[i]) end
  return b
end
SFX.stretch = function() return bellows(true) end
SFX.compress = function() return bellows(false) end

-- резьба: трещотка ускоряется, в конце щелчок и звон
SFX.screw = function()
  local b = buf(0.5)
  local t = 0
  for k = 1, 7 do
    local tt = t
    add(b, tt, 0.03, function(x) return noise() * exp(-x / 0.004) * 0.7 + sin(TAU * 2800 * x) * exp(-x / 0.006) * 0.4 end)
    t = t + 0.055 * (1 - k * 0.07)
  end
  add(b, t + 0.02, 0.4, function(x)
    return (sin(TAU * 1850 * x) * 0.5 + sin(TAU * 4270 * x) * 0.3 + sin(TAU * 6930 * x) * 0.15) * exp(-x / 0.09) + noise() * exp(-x / 0.003)
  end)
  return b
end

-- латунь «тум»: низкий удар с падением тона и неравномерный металлический обертон
SFX.push = function()
  local b = buf(0.45)
  local ph = 0
  add(b, 0, 0.45, function(t)
    ph = ph + (95 + 70 * exp(-t / 0.03)) / SR
    return sin(TAU * ph) * exp(-t / 0.09) * 0.9 + (sin(TAU * 523 * t) * 0.25 + sin(TAU * 1187 * t) * 0.15 + sin(TAU * 2011 * t) * 0.07) * exp(-t / 0.12)
      + noise() * exp(-t / 0.006) * 0.3
  end)
  return b
end

-- приземление: шлепок
SFX.land = function()
  local b = buf(0.3)
  local l = biquad("lp", 900, 0.9)
  add(b, 0, 0.3, function(t) return l(noise()) * exp(-t / 0.035) * 1.2 + sin(TAU * (70 + 40 * exp(-t / 0.02)) * t) * exp(-t / 0.07) * 0.8 end)
  return b
end

-- голова о фаянс: мыльный скрип
SFX.squeak = function()
  local b = buf(0.32)
  local ph = 0
  add(b, 0, 0.32, function(t)
    local f = 1250 + 500 * (t / 0.32) + 180 * sin(TAU * 38 * t)
    ph = ph + f / SR
    local e = math.min(1, t / 0.02) * math.min(1, (0.32 - t) / 0.06)
    return (sin(TAU * ph) + 0.35 * sin(TAU * ph * 2.01)) * e * 0.6
  end)
  return b
end

-- натянут: щипок струны (Карплус — Стронг)
SFX.taut = function()
  local b = buf(0.9)
  local N = floor(SR / 98)
  local ring = ffi.new("double[?]", N)
  for i = 0, N - 1 do ring[i] = noise() end
  local p = 0
  for i = 0, b.n - 1 do
    local nx = (p + 1) % N
    local v = 0.5 * (ring[p] + ring[nx]) * 0.996
    b.d[i] = ring[p]; ring[p] = v; p = nx
  end
  return b
end

-- упёрлось: глухой стук
SFX.blocked = function()
  local b = buf(0.2)
  local l = biquad("lp", 500, 1.2)
  add(b, 0, 0.2, function(t) return l(noise()) * exp(-t / 0.02) + sin(TAU * 140 * t) * exp(-t / 0.04) * 0.6 end)
  return b
end

-- закреплено намертво / деталь «окаменела»: короткий стальной звон
SFX.stone = function()
  local b = buf(0.7)
  add(b, 0, 0.7, function(t)
    return (sin(TAU * 612 * t) * 0.45 + sin(TAU * 1523 * t) * 0.3 + sin(TAU * 2891 * t) * 0.18 + sin(TAU * 4410 * t) * 0.08) * exp(-t / 0.16)
      + noise() * exp(-t / 0.004) * 0.4
  end)
  return b
end

-- «смыло»: бульканье слива — всплывающие пузыри и шум воронки
SFX.wash = function()
  local b = buf(1.5)
  local l = biquad("bp", 500, 0.7)
  add(b, 0, 1.5, function(t) return l(noise()) * 0.5 * math.min(1, t / 0.1) * math.min(1, (1.5 - t) / 0.5) end)
  for k = 1, 22 do
    local t0 = rnd() * 1.2
    local f0 = 250 + rnd() * 500
    local ph = 0
    add(b, t0, 0.09, function(t) ph = ph + f0 * (1 + 6 * t) / SR; return sin(TAU * ph) * exp(-t / 0.025) * 0.5 end)
  end
  return b
end

-- капля протечки
SFX.drip = function()
  local b = buf(0.25)
  local ph = 0
  add(b, 0, 0.25, function(t) ph = ph + (700 + 1300 * math.min(1, t / 0.04)) / SR; return sin(TAU * ph) * exp(-t / 0.05) * 0.8 end)
  return b
end

-- шипение струи: бесшовная петля 2 с
SFX.jet = function()
  local b = buf(2.0)
  local bp, hp = biquad("bp", 3000, 0.5), hp1(800)
  for i = 0, b.n - 1 do b.d[i] = hp(bp(noise())) * (0.8 + 0.2 * sin(TAU * 3 * i / SR)) end
  local x = floor(0.2 * SR) -- кроссфейд конца в начало
  for i = 0, x - 1 do local a = i / x; b.d[i] = b.d[i] * a + b.d[b.n - x + i] * (1 - a) end
  b.n = b.n - x
  return b
end

-- интерфейс: щелчок
SFX.click = function()
  local b = buf(0.06)
  add(b, 0, 0.06, function(t) return sin(TAU * 1900 * t) * exp(-t / 0.008) + noise() * exp(-t / 0.002) * 0.4 end)
  return b
end

-- победа: волна воды и короткий горн (до-ми-соль-до)
SFX.win = function()
  local b = buf(2.6)
  local l = biquad("lp", 2500, 0.7)
  add(b, 0, 2.6, function(t) return l(noise()) * 0.35 * math.min(1, t / 0.3) * exp(-max(0, t - 0.6) / 0.6) end)
  local notes = { { 0.15, 60 }, { 0.3, 64 }, { 0.45, 67 }, { 0.6, 72 } }
  for k, nt in ipairs(notes) do
    local f, dur = midi(nt[2]), (k == 4) and 1.6 or 0.2
    local ph, lpf = 0, lp1(1200)
    add(b, nt[1], dur, function(t)
      ph = ph + f * (1 + 0.004 * sin(TAU * 5.5 * t)) / SR
      local saw = (ph % 1) * 2 - 1
      local e = math.min(1, t / 0.03) * ((k == 4) and exp(-t / 0.7) or math.min(1, (dur - t) / 0.05))
      return lpf(saw) * e * 0.9
    end)
  end
  return b
end

-- ------------------------------------------------------------ инструменты для музыки
-- электропиано (FM, «родес»)
local function epiano(b, t0, m, dur, vel, wrap)
  local f = midi(m)
  add(b, t0, dur + 0.8, function(t)
    local e = env(t, 0.004, 0.6 + 0.4 * (60 / m)) * (t < dur and 1 or exp(-(t - dur) / 0.12))
    local idx = 1.6 * exp(-t / 0.25)
    return sin(TAU * f * t + idx * sin(TAU * f * t)) * e * vel + sin(TAU * f * 2 * t) * e * vel * 0.08
  end, wrap)
end
-- бас: синус с лёгкой перегрузкой
local function bass(b, t0, m, dur, vel, wrap)
  local f = midi(m)
  add(b, t0, dur + 0.05, function(t)
    local e = math.min(1, t / 0.008) * (t < dur and exp(-t / 1.2) or exp(-(t - dur) / 0.015))
    local x = sin(TAU * f * t) + 0.25 * sin(TAU * 2 * f * t)
    return math.tanh(x * 1.5) * e * vel
  end, wrap)
end
-- вибрафон (мелодия)
local function vibes(b, t0, m, dur, vel, wrap)
  local f = midi(m)
  add(b, t0, dur + 1.0, function(t)
    local trem = 1 + 0.25 * sin(TAU * 5 * t)
    local e = env(t, 0.003, 0.9) * (t < dur + 0.3 and 1 or exp(-(t - dur - 0.3) / 0.2))
    return (sin(TAU * f * t) + 0.2 * sin(TAU * 4 * f * t) * exp(-t / 0.1)) * e * trem * vel
  end, wrap)
end
local function rim(b, t0, vel, wrap)
  local l = lp1(4000)
  add(b, t0, 0.05, function(t) return l(sin(TAU * 1700 * t) * 0.7 + noise() * 0.4) * exp(-t / 0.007) * vel end, wrap)
end
local function shaker(b, t0, vel, wrap)
  local bp = biquad("bp", 6500, 0.9)
  add(b, t0, 0.08, function(t) return bp(noise()) * env(t, 0.01, 0.025) * vel end, wrap)
end
local function kick(b, t0, vel, wrap)
  add(b, t0, 0.3, function(t) return sin(TAU * (50 + 60 * exp(-t / 0.03)) * t) * exp(-t / 0.12) * vel end, wrap)
end

-- аккорды (MIDI) — лифтовая босса-нова: Cmaj7 Am7 Dm7 G7 | Em7 A7 Dm7 G7(b9)
local CHORDS = {
  { 48, { 64, 67, 71, 74 } }, { 45, { 64, 67, 72, 76 } }, { 50, { 65, 69, 72, 76 } }, { 43, { 65, 71, 74, 77 } },
  { 52, { 62, 67, 71, 74 } }, { 45, { 61, 67, 69, 76 } }, { 50, { 65, 69, 72, 74 } }, { 43, { 65, 68, 71, 74 } },
}
local MELODY = { -- { такт, доля (в восьмых), нота, длительность в восьмых }
  { 0, 0, 76, 3 }, { 0, 3, 74, 1 }, { 0, 4, 72, 2 }, { 0, 6, 71, 2 },
  { 1, 0, 72, 5 }, { 1, 6, 69, 2 },
  { 2, 0, 72, 2 }, { 2, 2, 74, 2 }, { 2, 4, 77, 3 }, { 2, 7, 76, 1 },
  { 3, 0, 74, 6 },
  { 4, 0, 71, 3 }, { 4, 3, 72, 1 }, { 4, 4, 74, 2 }, { 4, 6, 76, 2 },
  { 5, 0, 73, 4 }, { 5, 4, 76, 2 }, { 5, 6, 79, 2 },
  { 6, 0, 77, 3 }, { 6, 3, 76, 1 }, { 6, 4, 74, 2 }, { 6, 6, 72, 2 },
  { 7, 0, 71, 4 }, { 7, 4, 74, 4 },
}

local function bossa(bpm, dense, melodyOn)
  local beat = 60 / bpm
  local bar = 4 * beat
  local bars = 16
  local b = buf(bars * bar)
  local e8 = beat / 2
  -- клаве босса-новы на два такта (в восьмых): 0,3,6 | 10,13
  local clave = { 0, 3, 6, 10, 13 }
  for br = 0, bars - 1 do
    local c = CHORDS[br % 8 + 1]
    local t0 = br * bar
    -- бас: корень на 1, квинта на «и» второй доли, корень на 3, квинта на «и» четвёртой
    bass(b, t0, c[1], beat * 1.4, 0.55, true)
    bass(b, t0 + 1.5 * beat, c[1] + 7, beat * 0.45, 0.45, true)
    bass(b, t0 + 2 * beat, c[1], beat * 1.4, 0.5, true)
    bass(b, t0 + 3.5 * beat, c[1] + 7, beat * 0.45, 0.45, true)
    -- пиано: синкопированный комп
    for _, pos in ipairs({ 0, 3, 6 }) do
      for _, m in ipairs(c[2]) do epiano(b, t0 + pos * e8, m, e8 * 1.6, 0.11, true) end
    end
    for k = 0, 7 do shaker(b, t0 + k * e8, (k % 2 == 0) and 0.06 or 0.1, true) end
    for _, p in ipairs(clave) do
      local bb = floor(p / 8)
      if (br % 2) == bb then rim(b, t0 + (p % 8) * e8, 0.22, true) end
    end
    if dense then kick(b, t0, 0.6, true); kick(b, t0 + 2 * beat, 0.5, true) end
  end
  if melodyOn then
    for rep = 0, 1 do
      if rep == 1 or dense then
        for _, n in ipairs(MELODY) do vibes(b, (rep * 8 + n[1]) * bar + n[2] * e8, n[3], n[4] * e8, 0.22, true) end
      end
    end
  end
  return b
end

-- «подвал»: даб — глубокий бас, органный скэнк на слабые доли, рим с эхом, всё «сквозь трубы»
local function dub()
  local bpm = 74
  local beat = 60 / bpm
  local bar = 4 * beat
  local bars = 8
  local b = buf(bars * bar)
  local prog = { { 45, { 69, 72, 76 } }, { 45, { 69, 72, 76 } }, { 43, { 67, 71, 74 } }, { 41, { 65, 69, 72 } } }
  for br = 0, bars - 1 do
    local c = prog[br % 4 + 1]
    local t0 = br * bar
    bass(b, t0, c[1] - 12, beat * 1.7, 0.9, true)
    bass(b, t0 + 2.5 * beat, c[1] - 12 + ((br % 2 == 0) and 3 or 7), beat * 0.9, 0.7, true)
    bass(b, t0 + 3.5 * beat, c[1] - 12, beat * 0.4, 0.6, true)
    for k = 0, 3 do
      for _, m in ipairs(c[2]) do
        local f = midi(m)
        add(b, t0 + (k + 0.5) * beat, 0.16, function(t)
          return (sin(TAU * f * t) + 0.5 * sin(TAU * 2 * f * t) + 0.3 * sin(TAU * 3 * f * t)) * env(t, 0.005, 0.05) * 0.07
        end, true)
      end
    end
    kick(b, t0 + 2 * beat, 0.8, true) -- «one drop»
    rim(b, t0 + 2 * beat, 0.35, true)
  end
  -- эхо (1/8 с точкой) с затуханием — петля, поэтому по кругу
  local dly = floor(beat * 0.75 * SR)
  local tmp = ffi.new("double[?]", b.n)
  for pass = 1, 2 do
    for i = 0, b.n - 1 do tmp[i] = b.d[i] end
    for i = 0, b.n - 1 do b.d[i] = tmp[i] + 0.38 * tmp[(i - dly) % b.n] end
  end
  -- «сквозь трубы»: гребёнка и срез верхов
  local comb = floor(SR / 180)
  for i = 0, b.n - 1 do tmp[i] = b.d[i] end
  local l = lp1(1800)
  for i = 0, b.n - 1 do b.d[i] = l(tmp[i] + 0.35 * tmp[(i - comb) % b.n]) end
  return b
end

-- музыка ожидания горячей линии: тема босса-новы «через трубку» (300–3400 Гц) с плавающим тоном
local function hold()
  local b = bossa(118, false, true)
  local out = buf(b.n / SR)
  local hp, lp = biquad("hp", 350, 0.7), biquad("lp", 3000, 0.7)
  for i = 0, b.n - 1 do
    local w = 0.004 * sin(TAU * 0.7 * i / SR)
    local j = floor(i * (1 + w)) % b.n
    out.d[i] = lp(hp(b.d[j]))
  end
  return out
end

local MUSIC = {
  dub = dub,
  bossa = function() return bossa(126, false, true) end,
  pressure = function() return bossa(132, true, true) end,
  hold = hold,
}

-- ------------------------------------------------------------ запуск
local what = arg[1]
if what ~= "music" then
  local names = {}
  for k in pairs(SFX) do names[#names + 1] = k end
  table.sort(names)
  for _, k in ipairs(names) do seed = 777 + #k; toOgg(k, SFX[k](), "sfx", 0.9) end
end
if what ~= "sfx" then
  for _, k in ipairs({ "dub", "bossa", "pressure", "hold" }) do seed = 4242; toOgg(k, MUSIC[k](), "music", 0.8) end
end
