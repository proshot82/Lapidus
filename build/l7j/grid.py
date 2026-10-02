#!/usr/bin/env python3
# build/l7j/grid.py W H "x,y x,y ..." — печатает сетку: рамка из стен + внутренние стены по списку (для спецификаций)
import sys
W, H = int(sys.argv[1]), int(sys.argv[2])
walls = set()
for t in (sys.argv[3].split() if len(sys.argv) > 3 else []):
    x, y = t.split(","); walls.add((int(x), int(y)))
for y in range(1, H + 1):
    print("".join("#" if (x in (1, W) or y in (1, H) or (x, y) in walls) else "." for x in range(1, W + 1)))
