import sys, subprocess, re, itertools; sys.path.insert(0,'/home/user/Lapidus/build/l8j')
from mk import mk
P={'F':{'down':'N'},'S':{'down':'N'},'B':{'up':'V','down':'V'}}
W={'B':'coupling','F':'heater'}
def chk(name):
    o=subprocess.run(['luajit','build/l6b/check.lua','build/l8j/%s.lua'%name],cwd='/home/user/Lapidus',capture_output=True,text=True).stdout
    m=re.search(r'ходов (\d+).*?СКРЫТЫХ (\d+) %.*?ОБЕЗЬЯНА ([\d.]+).*?ГЛУБИНА (\d+).*?кратчайших (\d+), ширина (\d+)',o,re.S)
    return m.groups() if m else None
res=[]
Wd=13
for xB in (5,6,7):
  for xS in range(xB+3, 11):
    D=xS+1
    for a in range(xB+1, xS+1):
      for b in range(xS, D+1):
        rows=[['#']*Wd for _ in range(7)]
        rows[1][D-1]='F'; rows[2][xS-1]='S'; rows[2][D-1]='.'
        for x in range(2,D+1): rows[3][x-1]='.'; rows[4][x-1]='.'
        rows[3][xB-1]='B'; rows[4][xB-1]='P'
        rows[5][xB]='.'   # ямка под мылом
        for x in range(a,b+1): rows[5][x-1]='.'
        # лапидус длины 2 слева от мыла
        rows[4][xB-2]='f'; rows[4][xB-3]='H' if xB-3>=1 else '#'
        if xB-3<2: continue
        for x in range(2, xB-2): rows[4][x-1]='#'; rows[3][x-1]='#'
        rows[3][xB-3]='#'
        g=[''.join(r) for r in rows]
        try: mk('qs',g,P,what=W,washOk=True,mustLift=['B'],note='q sweep',L=(2,5))
        except AssertionError: continue
        r=chk('qs')
        print(xB,xS,a,b,r,flush=True)
        if False: 
          res.append((r,xB,xS,a,b)); print(r,xB,xS,a,b,flush=True)
