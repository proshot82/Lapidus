-- tools/uniq.lua 1 2 3 4 — уникальность решений: число выигрышных конечных положений, число кратчайших
-- последовательностей ходов (обход в ширину с подсчётом путей), и сколько из них отличаются не только
-- порядком двух соседних независимых ходов. Сами ходы не печатаются.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
for _, a in ipairs(arg) do
  local id = tonumber(a)
  local def = dofile(string.format("levels/%02d.lua", id))
  local lvl = R.compile(def)
  local s0 = R.newState(lvl)
  local k0 = R.key(s0)
  local dist, cnt, st, order = { [k0] = 0 }, { [k0] = 1 }, { [k0] = s0 }, { k0 }
  local wins, head, best = {}, 1, nil
  while head <= #order do
    local k = order[head]; head = head + 1
    local s = st[k]
    if best and dist[k] >= best then break end
    if not s.dead and not R.isWin(lvl, s) then
      for m = 1, 8 do
        local mv = R.MOVES[m]
        local ns = R.move(lvl, s, mv.which, mv.dir)
        if ns then
          local nk = R.key(ns)
          if dist[nk] == nil then
            dist[nk], cnt[nk], st[nk] = dist[k] + 1, cnt[k], ns
            order[#order + 1] = nk
            if R.isWin(lvl, ns) then wins[#wins + 1] = nk; best = best or dist[nk] end
          elseif dist[nk] == dist[k] + 1 then
            cnt[nk] = cnt[nk] + cnt[k]
          end
        end
      end
    end
  end
  local total, wcount = 0, 0
  for _, w in ipairs(wins) do if dist[w] == best then total = total + cnt[w]; wcount = wcount + 1 end end
  print(string.format("кв. %d «%s»: кратчайшее решение %d ходов; выигрышных конечных положений на этой длине: %d; разных кратчайших последовательностей ходов: %d",
    id, def.name, best or -1, wcount, total))
end
