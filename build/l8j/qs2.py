import sys, subprocess, re; sys.path.insert(0,'/home/user/Lapidus/build/l8j')
from mk import mk
P={'F':{'down':'N'},'S':{'down':'N'},'B':{'up':'V','down':'V'}}
W={'B':'coupling','F':'heater'}
def chk(name):
    o=subprocess.run(['luajit','build/l6b/check.lua','build/l8j/%s.lua'%name],cwd='/home/user/Lapidus',capture_output=True,text=True).stdout
    m=re.search(r'ходов (\d+).*?СКРЫТЫХ (\d+) %.*?ОБЕЗЬЯНА ([\d.]+).*?ГЛУБИНА (\d+).*?кратчайших (\d+), ширина (\d+)',o,re.S)
    return m.groups() if m else None
Wd=13; H=8
for xB in (4,5):
 for xS in range(xB+1, xB+5):
  for gap in (1,2):
   D=xS+gap
   if D>11: continue
   for a in range(xB, xS+1):
    for b in range(xS, D+1):
     for pit in (None, 'end', 'start'):
      rows=[['#']*Wd for _ in range(H)]
      rows[1][D-1]='F'; rows[2][xS-1]='S'
      for y in range(3, 3+(D==D)): pass
      if gap==1: rows[2][D-1]='.'
      else: rows[2][D-1]='.'; 
      for x in range(2,D+1): rows[3][x-1]='.'; rows[4][x-1]='.'
      rows[3][xB-1]='B'; rows[4][xB-1]='P'
      for x in range(a,b+1): rows[5][x-1]='.'
      if pit=='end': rows[5][b-1]='.'; rows[6][b-1]='.'; rows[7][b-1]='~'
      if pit=='start': rows[5][a-1]='.'; rows[6][a-1]='.'; rows[7][a-1]='~'
      rows[4][xB-2]='f'; rows[4][xB-3]='H'
      for x in range(2, xB-2): rows[4][x-1]='#'; rows[3][x-1]='#'
      rows[3][xB-3]='#'
      g=[''.join(r) for r in rows]
      if gap==2: pass
      try: mk('qs',g,P,what=W,washOk=True,mustLift=['B'],note='q sweep',L=(2,5))
      except AssertionError: continue
      r=chk('qs')
      if r: print(r,xB,xS,gap,a,b,pit,flush=True)
