#!/usr/bin/env python3
# build/l6c/a_f2plus/gates.py имя "замысел одной фразой" — прогон check.lua, разбор ворот, строка в LOG.md
import re, subprocess, sys
name, note = sys.argv[1], sys.argv[2]
path = 'build/l6c/a_f2plus/%s.lua' % name
out = subprocess.run(['luajit', 'build/l6b/check.lua', path], capture_output=True, text=True).stdout.strip()
lines = [l for l in out.split('\n') if l]
txt = ' / '.join(lines)
fail = []
def num(pat, cast=float):
    m = re.search(pat, out)
    return cast(m.group(1).replace(',', '.')) if m else None
if 'НЕРЕШАЕМ' in out or 'ОШИБКИ' in out:
    fail = ['нерешаем']
else:
    moves = num(r'ходов (\d+)', int); wins = num(r'выигрышных (\d+)', int)
    hid = num(r'СКРЫТЫХ (\d+)'); smart = num(r'ОБЕЗЬЯНА ([\d.]+)'); depth = num(r'ГЛУБИНА (\d+)', int)
    monkey = num(r'наобум ([\d.]+)'); width = num(r'ширина (\d+)', int)
    ev = num(r'событий (\d+)', int); walk = num(r'прогулка max (\d+)', int)
    safe = re.search(r'по шагам: (\d+)', out).group(1)
    forced = max((len(r) for r in re.findall(r'1+', safe)), default=0)
    if monkey is None or monkey > 1 or width > 3: fail.append('1-строгие')
    if hid < 40: fail.append('2-скрытых')
    if smart > 0.2: fail.append('3-обезьяна')
    if depth < 8: fail.append('4-глубина')
    if walk > 6: fail.append('5-прогулка')
    if forced > 4: fail.append('6-вынужд(%d)' % forced)
    if wins != 1: fail.append('7-выигрышных')
    if 'РЕШАЕМ' in out.replace('НЕРЕШАЕМ', ''): fail.append('8-абляция')
    if not (15 <= moves <= 40) or ev < 2: fail.append('10-коридор')
print(out)
print('ПРОВАЛ: ' + (', '.join(fail) if fail else 'нет (8 и 9 — вручную)'))
with open('build/l6c/a_f2plus/LOG.md', 'a', encoding='utf-8') as f:
    f.write('| %s | %s | %s | %s |\n' % (name, note, txt.replace('|', '/'), ', '.join(fail) if fail else '—'))
