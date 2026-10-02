import sys, subprocess, re, itertools; sys.path.insert(0,'/home/user/Lapidus/build/l8j')
from mk import mk
P={'F':{'down':'N'},'S':{'down':'N'},'B':{'up':'V','down':'V'}}
W={'B':'coupling','F':'heater'}
base=["##########",
      "#######F##",
      "######S.##",
      "##.B....##",
      "#HfP....##",
      "####....##",
      "####.#####",
      "####~#####"]
cells=[(3,4),(2,4),(6,6),(7,6),(8,6),(9,4),(9,5),(9,6),(5,4),(6,4)]
def chk(name):
    o=subprocess.run(['luajit','build/l6b/check.lua','build/l8j/%s.lua'%name],cwd='/home/user/Lapidus',capture_output=True,text=True).stdout
    m=re.search(r'ходов (\d+).*?СКРЫТЫХ (\d+) %.*?ОБЕЗЬЯНА ([\d.]+).*?ГЛУБИНА (\d+).*?кратчайших (\d+), ширина (\d+)',o,re.S)
    return m.groups() if m else None
for mask in range(1<<len(cells)):
    g=[list(r) for r in base]
    for i,(x,y) in enumerate(cells):
        if mask>>i&1:
            g[y-1][x-1] = '#' if g[y-1][x-1]=='.' else '.'
    rows=[''.join(r) for r in g]
    if rows[0][8]!='#': continue
    try: mk('qt',rows,P,what=W,washOk=True,mustLift=['B'],note='t',L=(2,5))
    except AssertionError: continue
    r=chk('qt')
    if r and int(r[5])<=5: print(r, mask, rows, flush=True)
