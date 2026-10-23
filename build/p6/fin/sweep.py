import sys, subprocess, re, random, os
random.seed(int(sys.argv[1])); N = int(sys.argv[2]); tag = sys.argv[3]
W_ = os.path.dirname(os.path.abspath(__file__))
base = open(os.path.join(W_, 'e1.lua')).read()
def mk(rows, cpl, nip, lap, L, name):
    s = re.sub(r'grid = \{.*?\n  \}', 'grid = {\n' + '\n'.join('    "%s",' % r for r in rows) + '\n  }', base, flags=re.S)
    s = s.replace('at = { 10, 5 }, ports = { left = "V"', 'at = { %d, %d }, ports = { left = "V"' % cpl)
    s = s.replace('at = { 12, 5 }, ports = { left = "N"', 'at = { %d, %d }, ports = { left = "N"' % nip)
    s = re.sub(r'cells = \{.*\}, head', 'cells = { %s }, head' % ', '.join('{ %d, %d }' % c for c in lap), s)
    return s.replace('length = { 2, 6 }', 'length = { 2, %d }' % L).replace('name = "e1"', 'name = "%s"' % os.path.basename(name))
seen = set()
for t in range(N):
    top = random.choice([2, 2, 3])
    rows = [list("##############")] + [list("#######......#") for _ in range(4)] + [list("#............#"), list("#######~~#####")]
    for y in range(1, top): rows[y] = list("##############")
    rows[3][8] = '#'
    nled = random.randint(1, 3)
    for _ in range(nled):
        x = random.randint(10, 13); y = random.randint(top + 1, 5)
        if (x, y) != (10, 5): rows[y - 1][x - 1] = '#'
    if random.random() < 0.3:
        x = random.randint(11, 13); rows[5][x - 1] = '#'
    rows = [''.join(r) for r in rows]
    def free(x, y): return rows[y - 1][x - 1] == '.'
    def solid(x, y): return rows[y - 1][x - 1] == '#' or (x, y) == (10, 6)
    opts = []
    for y in range(top, 7):
        for x in range(10, 12):
            if all(free(x + i, y) for i in range(3)) and not (y == 6 and x < 11):
                opts.append([(x, y), (x + 1, y), (x + 2, y)])
    if not opts: continue
    lap = random.choice(opts)
    if random.random() < 0.5: lap = lap[::-1]
    occ = set(lap)
    def rest(x, y): return solid(x, y + 1) or (x, y + 1) in occ
    cells = [(x, y) for y in range(top, 7) for x in range(10, 14) if free(x, y) and (x, y) not in occ and rest(x, y) and (x, y) != (10, 5)]
    if len(cells) < 2: continue
    cpl, nip = random.sample(cells, 2)
    if cpl[1] == nip[1] and abs(cpl[0] - nip[0]) == 1: continue
    L = random.choice([5, 6, 6])
    key = (tuple(rows), cpl, nip, tuple(lap), L)
    if key in seen: continue
    seen.add(key)
    name = os.path.join(W_, 'srch', '%s_%d.lua' % (tag, t))
    open(name, 'w').write(mk(rows, cpl, nip, lap, L, name))
    r = subprocess.run(['luajit', os.path.join(W_, 'ev.lua'), name], cwd='/home/user/Lapidus', capture_output=True, text=True).stdout
    m = re.search(r'реш ходов (\d+) состояний (\d+)', r)
    if m and int(m.group(1)) >= 24:
        print(name, m.group(1), m.group(2), flush=True)
    else:
        os.remove(name)
