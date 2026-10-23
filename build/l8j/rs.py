import sys, subprocess, re; sys.path.insert(0,'/home/user/Lapidus/build/l8j')
from mk import mk
P={'F':{'down':'N'},'S':{'down':'N'},'B':{'up':'V','down':'V'}}
W={'B':'coupling','F':'heater'}
def chk(name):
    o=subprocess.run(['luajit','build/l6b/check.lua','build/l8j/%s.lua'%name],cwd='/home/user/Lapidus',capture_output=True,text=True).stdout
    m=re.search(r'ходов (\d+).*?СКРЫТЫХ (\d+) %.*?ОБЕЗЬЯНА ([\d.]+).*?ГЛУБИНА (\d+).*?кратчайших (\d+), ширина (\d+)',o,re.S)
    return m.groups() if m else None
Wd=13
for xB in (3,4):
 for xS in range(xB+1, 11):
  for gap in (1,2):
   D=xS+gap
   if D>11: continue
   for a in range(xB+1, xS+1):
    for L0 in ('R','L'):
      rows=[['#']*Wd for _ in range(7)]
      rows[1][D-1]='F'; rows[2][xS-1]='S'; rows[2][D-1]='.'
      for x in range(2,D+1): rows[3][x-1]='.'; rows[4][x-1]='.'
      rows[3][xB-1]='B'; rows[4][xB-1]='P'
      rows[5][xB-2]='.'  # ямка слева
      for x in range(a,D+1): rows[5][x-1]='.'
      if L0=='R': rows[4][xB]='f'; rows[4][xB+1]='H'
      else: rows[4][xB-2]='f'; rows[4][xB-3]='H' if xB>=4 else 'H'
      g=[''.join(r) for r in rows]
      try: mk('rs',g,P,what=W,washOk=True,mustLift=['B'],note='rs',L=(2,5))
      except AssertionError: continue
      r=chk('rs')
      if r: print(r,xB,xS,gap,a,L0,flush=True)
