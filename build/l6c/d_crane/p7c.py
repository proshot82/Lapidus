import sys; sys.path.insert(0, '/home/user/Lapidus/build/l6c/d_crane')
from p7gen import level, run
names = []
for dist in (2, 3):
    for chim in (2, 3):
        for left in (1, 2, 3):
            for right in (1, 2, 3):
                nx = 1 + left + 1; kx = nx + dist
                for L in (5, 6):
                    xs = list(range(kx - L + 1, kx + 1))
                    if xs[0] < 2 or nx not in xs: continue
                    cells = xs  # голова справа над муфтой
                    n = 'px_d%d_c%d_l%d_r%d_L%d' % (dist, chim, left, right, L)
                    level(n, dist, chim, 2, left, right, cells, Lr=(3, 6))
                    names.append(n)
out = run(names)
keep = []
for line in out.splitlines():
    if line.startswith('   '): continue
    if 'НЕРЕШАЕМ' in line or 'ОШИБКИ' in line: 
        import os; os.remove('/home/user/Lapidus/build/l6c/d_crane/%s.lua' % line.split(':')[0]); continue
    print(line)
