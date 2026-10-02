#!/usr/bin/env python3
# mk.py — ASCII-раскладка → файл уровня (кв. 6, направление C). Для себя: быстрые итерации над ручным ядром.
# Использование из python: make(name, rows, objs, lap, length=(3,4), comment="", extra="")
# rows — строки поля (#, ., ~); objs — список строк-объектов Lua; lap — "{ {x,y}, ... }, head = N".
import os
HERE = os.path.dirname(os.path.abspath(__file__))
REL = "build/l6c/c_stub_ladder"

def make(name, rows, objs, lap, length=(3, 4), comment="", abl=None, vis="vis.lua"):
    g = ",\n    ".join('"%s"' % r for r in rows)
    o = "\n".join("    " + s + "," for s in objs)
    ab = ("  ablations = %s,\n" % abl) if abl else ""
    txt = """-- %s (кв. 6 «Намертво», направление C «лестница на глухом отводе»). Решения здесь нет.
%s
return {
  visibleLoss = dofile("%s/%s"),
  id = 6, flat = 6, name = "Намертво", length = { %d, %d }, pressure = 0, tile = "mustard",
  grid = {
    %s,
  },
  objects = {
%s
    { kind = "lapidus", cells = %s },
  },
%s}
""" % (name, "\n".join("-- " + l for l in comment.splitlines()), REL, vis, length[0], length[1], g, o, lap, ab)
    open(os.path.join(HERE, name + ".lua"), "w", encoding="utf-8").write(txt)
    return os.path.join(REL, name + ".lua")
