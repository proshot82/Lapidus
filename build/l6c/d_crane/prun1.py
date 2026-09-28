import sys; sys.path.insert(0, '/home/user/Lapidus/build/l6c/d_crane')
from pgen import level, run
names = []
# вариации: высота колонки (up=2: один толчок, up=3: два), глубина кармана, расстояние ниппель–муфта, старт
for up in (2, 3):
    cy = up + 3
    for dist in (2, 3):
        nx = 4; kx = nx + dist; W = kx + 4
        for pocket in (2, 3):
            # старт: ноги слева у ниппеля, голова справа у муфты (нужен разворот), длина 5
            cells = [(nx - 1 + i, cy) for i in range(5)] if dist == 2 else [(nx - 1 + i, cy) for i in range(5)]
            n = 'pg_u%d_d%d_p%d' % (up, dist, pocket)
            level(n, nx, kx, W, up=up, pocket=pocket, cells=cells)
            names.append(n)
print(run(names))
