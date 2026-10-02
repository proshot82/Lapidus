#!/usr/bin/env python3
# build/l7j/try.py база.lua выход.lua "x,y=#|." ... — правка клеток сетки кандидата
import sys, re
src, out = sys.argv[1], sys.argv[2]
s = open(src).read()
m = re.search(r'  grid = \{\n(.*?)\n  \},', s, re.S)
rows = [re.search(r'"(.*)"', l).group(1) for l in m.group(1).split('\n')]
for t in sys.argv[3:]:
    xy, ch = t.split('='); x, y = map(int, xy.split(','))
    r = rows[y-1]; rows[y-1] = r[:x-1] + ch + r[x:]
new = '  grid = {\n' + '\n'.join('    "%s",' % r for r in rows) + '\n  },'
open(out, 'w').write(s[:m.start()] + new + s[m.end():])
