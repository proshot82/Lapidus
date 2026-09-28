import subprocess, itertools
base = [
"#########",
"##c#n####",
"#.......#",
"##A#B#.##",
"##A#B#.##",
"##S#F####",
"#########",
]
def build(name, rows, lap, extra=''):
    g = [list(r) for r in rows]
    for (x,y),ch in lap.items(): g[y-1][x-1] = ch
    txt = '\n'.join(''.join(r) for r in g).replace('A','.').replace('B','.')
    spec = txt + '\n\nS: source up=N\nF: heater up=V\nc: coupling tag=pc up=V down=V\nn: nipple tag=pn up=N down=N\n' + extra
    subprocess.run(['python3','gen.py','tmp/lv/'+name], input=spec, text=True, capture_output=True)
# варианты: старт Лапидуса (голова слева/справа), глубина кармана A/B
starts = {
 'hL': {(2,3):'H',(3,3):'o',(4,3):'o',(5,3):'o',(6,3):'f'},
 'hR': {(2,3):'f',(3,3):'o',(4,3):'o',(5,3):'o',(6,3):'H'},
 'hL4': {(3,3):'H',(4,3):'o',(5,3):'o',(6,3):'f'},
 'hL3': {(3,3):'H',(4,3):'o',(5,3):'f'},
}
for sn, lap in starts.items():
    build('l_'+sn, base, lap)
    r2 = list(base); r2[4] = "##A#F#.##"; r2[5] = "##S######"  # B глубины 1
    build('l_'+sn+'_b1', r2, lap)
    r3 = list(base); r3[3] = "##A#B####"; r3[4] = "##A#B####"  # без кармана 7
    build('l_'+sn+'_n7', r3, lap)
