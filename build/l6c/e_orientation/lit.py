#!/usr/bin/env python3
# lit.py src dst "old=>new" [...] — литеральные замены (без регулярных выражений) при копировании кандидата.
import sys
src, dst = sys.argv[1], sys.argv[2]
s = open(src, encoding='utf-8').read()
for rep in sys.argv[3:]:
    old, new = rep.split('=>', 1)
    old = old.replace('\\n', '\n'); new = new.replace('\\n', '\n')
    if old not in s: sys.exit('нет подстроки: ' + old)
    s = s.replace(old, new, 1)
open(dst, 'w', encoding='utf-8').write(s)
