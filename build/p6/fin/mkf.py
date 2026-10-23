# генератор вариантов на основе e1: python3 mkf.py имя "ряд|ряд|..." cx,cy nx,ny "x,y;x,y;x,y"(голова первой) Lmax
import sys, re
base = open('e1.lua').read()
name, rows, cpl, nip, lap, L = sys.argv[1], sys.argv[2].split('|'), sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6]
s = re.sub(r'grid = \{.*?\n  \}', 'grid = {\n' + '\n'.join('    "%s",' % r for r in rows) + '\n  }', base, flags=re.S)
s = s.replace('at = { 10, 5 }, ports = { left = "V"', 'at = { %s }, ports = { left = "V"' % cpl.replace(',', ', '))
s = s.replace('at = { 12, 5 }, ports = { left = "N"', 'at = { %s }, ports = { left = "N"' % nip.replace(',', ', '))
s = re.sub(r'cells = \{.*\}, head', 'cells = { %s }, head' % ', '.join('{ %s }' % c.replace(',', ', ') for c in lap.split(';')), s)
s = s.replace('length = { 2, 6 }', 'length = { 2, %s }' % L).replace('name = "e1"', 'name = "%s"' % name)
open(name + '.lua', 'w').write(s)
