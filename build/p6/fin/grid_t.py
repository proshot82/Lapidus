import sys, itertools, subprocess, re
base = open('e1.lua').read()
res = []
rows = ["##############","#######......#","#######......#","#######.#....#","#######......#","#............#","#######~~#####"]
def mk(ledges, cpl, nip, lap, name='t2.lua'):
    g = [list(r) for r in rows]
    for (x,y) in ledges: g[y-1][x-1] = '#'
    s = base
    s = re.sub(r'grid = \{.*?\n  \}', 'grid = {\n' + '\n'.join('    "%s",' % ''.join(r) for r in g) + '\n  }', s, flags=re.S)
    s = s.replace('at = { 10, 5 }, ports = { left = "V"', 'at = { %d, %d }, ports = { left = "V"' % cpl)
    s = s.replace('at = { 12, 5 }, ports = { left = "N"', 'at = { %d, %d }, ports = { left = "N"' % nip)
    s = re.sub(r'cells = \{.*\}, head', 'cells = { %s }, head' % ', '.join('{ %d, %d }' % c for c in lap), s)
    open(name, 'w').write(s)
lap = [(11,6),(12,6),(13,6)]
cands = []
for lx in range(10, 14):
    for ly in range(3, 6):
        if (lx, ly) == (10,5): continue
        for nx in range(10, 14):
            ny = ly - 1
            if nx != lx: continue
            cands.append(((lx,ly),(nx,ny)))
out = []
for (ledge, nip) in cands:
    for cpl in [(11,5),(12,5),(13,5)]:
        mk([ledge], cpl, nip, lap)
        r = subprocess.run(['luajit','build/p6/fin/ev.lua','build/p6/fin/t2.lua'], cwd='/home/user/Lapidus', capture_output=True, text=True).stdout
        if ' реш' in r:
            print(ledge, cpl, nip, r.strip().split(None,1)[1], flush=True)
