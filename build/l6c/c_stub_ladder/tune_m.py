#!/usr/bin/env python3
# tune_m.py — локальная доводка ядра M4 (старт, длина, мелкие стены). Генерирует файлы tmp_*.lua и печатает список.
import sys, itertools
HEAD = open('m4.lua', encoding='utf-8').read()
def variant(name, grid=None, lap=None, length=None, objs=None, comment=None):
    s = HEAD
    if grid:
        import re
        start = s.index('grid = {'); end = s.index('},', start)
        body = ',\n    '.join('"%s"' % r for r in grid)
        s = s[:start] + 'grid = {\n    ' + body + ',\n  ' + s[end:]
    if lap:
        import re
        a = s.index('{ kind = "lapidus"'); b = s.index('\n', a)
        s = s[:a] + '{ kind = "lapidus", cells = %s },' % lap + s[b:]
    if length:
        s = s.replace('length = { 3, 4 }', 'length = { %d, %d }' % length)
    if objs:
        for old, new in objs: s = s.replace(old, new)
    if comment:
        s = s.replace('-- m4 (', '-- %s (' % name, 1).replace('Замысел M4:', comment + ' Замысел M4:', 1)
    else:
        s = s.replace('-- m4 (', '-- %s (' % name, 1)
    open(name + '.lua', 'w', encoding='utf-8').write(s)
    return name + '.lua'
if __name__ == '__main__':
    pass
