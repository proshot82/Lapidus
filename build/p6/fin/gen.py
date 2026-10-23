#!/usr/bin/env python3
# build/p6/fin/gen.py имя LEN "x,y;x,y;..."(голова первой) ряд1 ряд2 ...
# Символы: # стена, ~ слив, . пусто, F колонка (вход справа, В), S стояк (выход влево, Н),
#          c муфта (В|В), n ниппель (Н|Н), T глухой отвод (В вниз)  — остальное пусто
import sys
name, ln, lap = sys.argv[1], sys.argv[2], sys.argv[3]
rows = sys.argv[4:]
objs, grid = [], []
for y, r in enumerate(rows, 1):
    g = ''
    for x, ch in enumerate(r, 1):
        if ch in '#~.':
            g += ch; continue
        g += '.'
        if ch == 'F': objs.append('{ kind = "fixture", what = "heater", at = { %d, %d }, ports = { right = "V" } }' % (x, y))
        elif ch == 'G': objs.append('{ kind = "fixture", what = "heater", at = { %d, %d }, ports = { left = "V" } }' % (x, y))
        elif ch == 'S': objs.append('{ kind = "source", at = { %d, %d }, ports = { left = "N" } }' % (x, y))
        elif ch == 'Z': objs.append('{ kind = "source", at = { %d, %d }, ports = { right = "N" } }' % (x, y))
        elif ch == 'c': objs.append('{ kind = "fitting", what = "coupling", tag = "cpl", at = { %d, %d }, ports = { left = "V", right = "V" } }' % (x, y))
        elif ch == 'n': objs.append('{ kind = "fitting", what = "nipple", tag = "nip", at = { %d, %d }, ports = { left = "N", right = "N" } }' % (x, y))
        elif ch == 'p': objs.append('{ kind = "porcelain", what = "soap", tag = "soap", at = { %d, %d } }' % (x, y))
        else: raise SystemExit('bad char ' + ch)
    grid.append(g)
cells = ', '.join('{ %s }' % c.replace(',', ', ') for c in lap.split(';'))
lo, hi = ln.split(',')
open(name + '.lua', 'w', encoding='utf-8').write('''return {
  id = 10, flat = 10, name = "%s", length = { %s, %s }, pressure = 0, tile = "mustard",
  grid = {
%s
  },
  objects = {
%s
    { kind = "lapidus", cells = { %s }, head = 1 },
  },
}
''' % (name, lo, hi, '\n'.join('    "%s",' % g for g in grid), '\n'.join('    %s,' % o for o in objs), cells))
