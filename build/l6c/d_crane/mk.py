#!/usr/bin/env python3
# mk.py — ASCII-раскладка → файл уровня (кв. 6, направление D «Он сам себе кран»). Для себя: быстрые итерации над ручным ядром.
# from mk import make; make(name, rows, objs, lap, length=(3,5), comment="", abl=None, vis="vis.lua", extra="")
import os
HERE = os.path.dirname(os.path.abspath(__file__))
REL = "build/l6c/d_crane"

def make(name, rows, objs, lap, length=(3, 5), comment="", abl=None, vis="vis.lua", extra=""):
    g = ",\n    ".join('"%s"' % r for r in rows)
    o = "\n".join("    " + s + "," for s in objs)
    ab = ("  ablations = %s,\n" % abl) if abl else ""
    txt = """-- %s (кв. 6 «Намертво», направление D «Он сам себе кран»). Решения здесь нет.
%s
return {
  visibleLoss = dofile("%s/%s"),
%s  id = 6, flat = 6, name = "Намертво", length = { %d, %d }, pressure = 0, tile = "mustard",
  grid = {
    %s,
  },
  objects = {
%s
    { kind = "lapidus", cells = %s },
  },
%s}
""" % (name, "\n".join("-- " + l for l in comment.splitlines()), REL, vis, extra, length[0], length[1], g, o, lap, ab)
    open(os.path.join(HERE, name + ".lua"), "w", encoding="utf-8").write(txt)
    return os.path.join(REL, name + ".lua")

def build(name, amap, objs, lap, length=(3, 5), comment="", abl=None, vis="vis0.lua", extra="", cells=None):
    """amap: строки с символами объектов; objs: {символ: 'lua-объект с {x},{y}'}; lap: строка ячеек Лапидуса
    через символы: 'h' — голова, 'f' — ноги, 'o' — тело (порядок восстанавливается по соседству)."""
    rows = []
    found = {}
    lapcells = {}
    for y, r in enumerate(amap, 1):
        out = []
        for x, ch in enumerate(r, 1):
            if ch in "#.~":
                out.append(ch)
            else:
                out.append(".")
                if ch in "hfo":
                    lapcells[(x, y)] = ch
                else:
                    found.setdefault(ch, []).append((x, y))
        rows.append("".join(out))
    lo = []
    for ch, pcs in found.items():
        for (x, y) in pcs:
            lo.append(objs[ch].replace("{x}", str(x)).replace("{y}", str(y)))
    if cells:
        lapstr = "{ " + ", ".join("{ %d, %d }" % c for c in cells) + " }, head = %d" % len(cells)
        return make(name, rows, lo, lapstr, length=length, comment=comment, abl=abl, vis=vis, extra=extra)
    # восстановить порядок тела от ног к голове
    start = [c for c, v in lapcells.items() if v == "f"][0]
    order = [start]
    rest = set(lapcells) - {start}
    while rest:
        x, y = order[-1]
        nxt = [c for c in rest if abs(c[0] - x) + abs(c[1] - y) == 1]
        assert len(nxt) >= 1, "lapidus broken"
        if len(nxt) > 1:
            nxt = [c for c in nxt if lapcells[c] == "o"] or nxt
        order.append(nxt[0]); rest.discard(nxt[0])
    assert lapcells[order[-1]] == "h", "head must be last"
    lapstr = "{ " + ", ".join("{ %d, %d }" % c for c in order) + " }, head = %d" % len(order)
    return make(name, rows, lo, lapstr, length=length, comment=comment, abl=abl, vis=vis, extra=extra)
