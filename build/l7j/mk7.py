#!/usr/bin/env python3
# build/l7j/mk7.py имя — собрать кандидата из спецификации в build/l7j/specs/<имя>.txt
# Формат спецификации: строка L=a,b; строки сетки (#.~); после пустой строки — объекты по одному в строке в синтаксисе Lua;
# после второй пустой строки — абляции (Lua). Решение не пишется.
import sys, os
name = sys.argv[1]
src = open(f"build/l7j/specs/{name}.txt").read().rstrip("\n").split("\n\n")
head = src[0].split("\n")
L = head[0].split("=")[1].split(",")
grid = head[1:]
objs = [o for o in src[1].split("\n") if o.strip()]
abl = [a for a in (src[2].split("\n") if len(src) > 2 else []) if a.strip()]
out = [f"-- l7j {name}: кандидат кв. 7 (собран build/l7j/mk7.py). Решение не пишется.",
       'local okV, vis = pcall(dofile, "build/l6j/vis.lua")',
       "return {", "  visibleLoss = okV and vis or nil,",
       f'  id = 7, flat = 7, name = "{name}",',
       f"  length = {{ {L[0]}, {L[1]} }}, pressure = 0, tile = \"mint\",",
       "  target = { moves = { 15, 40 }, states = 100000, dead = 40, fb = 2 },", "  grid = {"]
w = len(grid[0])
for r in grid:
    assert len(r) == w, r
    out.append(f'    "{r}",')
out += ["  },", "  objects = {"] + [f"    {o}," for o in objs] + ["  },", "  ablations = {"] + [f"    {a}," for a in abl] + ["  },",
        '  texts = { request = "", hints = { "", "", "" } },', "}"]
open(f"build/l7j/{name}.lua", "w").write("\n".join(out) + "\n")
