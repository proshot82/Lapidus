import sys, subprocess, re; sys.path.insert(0,'/home/user/Lapidus/build/l8j')
from mk import mk
P={'F':{'down':'N'},'S':{'down':'N'},'B':{'up':'V','down':'V'}}
W={'B':'coupling','F':'heater'}
def chk(name):
    o=subprocess.run(['luajit','build/l6b/check.lua','build/l8j/%s.lua'%name],cwd='/home/user/Lapidus',capture_output=True,text=True).stdout
    m=re.search(r'ходов (\d+).*?СКРЫТЫХ (\d+) %.*?ОБЕЗЬЯНА ([\d.]+).*?ГЛУБИНА (\d+).*?кратчайших (\d+), ширина (\d+)',o,re.S)
    return m.groups() if m else None
def census(name):
    o=subprocess.run(['luajit','build/l8j/census.lua','build/l8j/%s.lua'%name],cwd='/home/user/Lapidus',capture_output=True,text=True).stdout
    return [l for l in o.split('\n') if re.search(r'скрытых +[1-9]',l)]
Wd=12
for xS in (6,7,8):
 for gap in (1,2):
  D=xS+gap
  for a in (3,4,5):
   for drain in ('none','end','endwall'):
    rows=[['#']*Wd for _ in range(7)]
    rows[1][D-1]='F'; rows[2][xS-1]='S'; rows[2][D-1]='.'
    for x in range(2,D+1): rows[3][x-1]='.'; rows[4][x-1]='.'
    rows[3][3]='B'; rows[4][3]='P'; rows[3][2]='H'; rows[4][2]='f'
    for x in range(a,D+1):
      if x!=4: rows[5][x-1]='.'
    if drain=='end': rows[5][D]='.'; rows[6][D]='~'
    if drain=='endwall': rows[6][D-1]='~'
    g=[''.join(r) for r in rows]
    try: mk('rs2',g,P,what=W,washOk=True,mustLift=['B'],note='rs2',L=(2,5))
    except AssertionError: continue
    r=chk('rs2')
    if r: print(r,xS,gap,a,drain,census('rs2')[:3],flush=True)
