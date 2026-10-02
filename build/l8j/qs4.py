import sys, subprocess, re, itertools; sys.path.insert(0,'/home/user/Lapidus/build/l8j')
from mk import mk
P={'F':{'down':'N'},'S':{'down':'N'},'B':{'up':'V','down':'V'}}
W={'B':'coupling','F':'heater'}
base=["##########","########F#","######S#.#","##.B.....#","#HfP.....#","####....##","####.#####","####~#####"]
cells=[(8,5),(7,6),(8,6),(6,6),(9,4),(9,5),(3,4),(5,4)]
def chk(name):
    o=subprocess.run(['luajit','build/l6b/check.lua','build/l8j/%s.lua'%name],cwd='/home/user/Lapidus',capture_output=True,text=True).stdout
    m=re.search(r'ходов (\d+).*?СКРЫТЫХ (\d+) %.*?ОБЕЗЬЯНА ([\d.]+).*?ГЛУБИНА (\d+).*?кратчайших (\d+), ширина (\d+)',o,re.S)
    return m.groups() if m else None
for k in (1,2):
  for comb in itertools.combinations(cells,k):
    g=[list(r) for r in base]
    for (x,y) in comb: g[y-1][x-1] = '#' if g[y-1][x-1]=='.' else '.'
    rows=[''.join(r) for r in g]
    try: mk('qt',rows,P,what=W,washOk=True,mustLift=['B'],note='t',L=(2,5))
    except AssertionError: continue
    print(comb, chk('qt'), flush=True)
