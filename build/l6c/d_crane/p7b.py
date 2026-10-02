import sys; sys.path.insert(0, '/home/user/Lapidus/build/l6c/d_crane')
from p7gen import level, run
names = []
for up in (3, 4):
    for chim in (2, 3):
        for dist in (2, 3):
            for left in (1, 2, 3):
                nx = 1 + left + 1; kx = nx + dist
                for L in (4, 5):
                    xs = list(range(kx - L + 1, kx + 1))
                    if xs[0] < 2 or nx not in xs: continue
                    for ori in ('R', 'L'):
                        cells = xs if ori == 'R' else list(reversed(xs))
                        n = 'pu%d_c%d_d%d_l%d_L%d%s' % (up, chim, dist, left, L, ori)
                        level(n, dist, chim, 2, left, 2, cells, up=up)
                        names.append(n)
out = run(names)
for line in out.splitlines():
    if line.startswith('   '): continue
    if 'НЕРЕШАЕМ' in line: continue
    print(line)
