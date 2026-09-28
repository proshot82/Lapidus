# gen19.py — ручные варианты ядра a19 («антресоль → переходник на фонтане → угольник сбоку последним»).
# Для каждого варианта пишет <имя>.lua (узкий честный visibleLoss) и <имя>w.lua (широкий).
import sys; sys.path.insert(0, '/home/user/Lapidus/build/l7c/a_lift_last')
import vislib
D = '/home/user/Lapidus/build/l7c/a_lift_last/'
HEAD = '''-- %s (напор %d): %s
return {
  id = 7, flat = 7, name = "Дали напор",
  length = { %d, %d }, pressure = %d,
  grid = {
%s  },
  objects = {
%s  },
}
'''
def obj(kind, at, ports=None, tag=None, what=None):
    s = '    { kind = "%s"' % kind
    if what: s += ', what = "%s"' % what
    if tag: s += ', tag = "%s"' % tag
    s += ', at = { %d, %d }' % at
    if ports: s += ', ports = { %s }' % ', '.join('%s = "%s"' % kv for kv in ports.items())
    return s + ' },\n'
def lap(cells, head):
    return '    { kind = "lapidus", cells = { %s }, head = %d },\n' % (', '.join('{ %d, %d }' % c for c in cells), head)
def write(name, idea, grid, objs, L=(2,5), R=3):
    txt = HEAD % (name, R, idea, L[0], L[1], R, ''.join('    "%s",\n' % r for r in grid), ''.join(objs))
    open(D + name + '.lua', 'w').write(vislib.make(txt))
    open(D + name + 'w.lua', 'w').write(vislib.make(txt, True))
