import os, sys, subprocess
sys.path.insert(0, 'art')
import gen, gen2
from gen import R, G
from gen2 import Q, port2, defs2
D = gen.DEFS + defs2(120, 0, 0, 'mustard')
parts = [R(0, 0, 1040, 560, '#8FA89B')]
for i, wet in enumerate((False, True)):
    cx, cy = 260 + i * 520, 290
    parts.append(R(cx - 120, cy - 120, 240, 240, 'none', stroke='#ffffff', stroke_width=2, stroke_dasharray='8 8'))
    parts.append(G(gen2.heater2(cx, cy, 240, wet) + port2(cx, cy - .02 * 240, 240, 'down', 'V', True), filter='url(#dsh)'))
svg = '<svg xmlns="http://www.w3.org/2000/svg" width="1040" height="560" viewBox="0 0 1040 560"><defs>%s</defs>%s</svg>' % (D, ''.join(parts))
open('build/l6/prev/heater.svg', 'w').write(svg)
subprocess.run(['rsvg-convert', '-o', 'build/l6/prev/heater.png', 'build/l6/prev/heater.svg'], check=True)
print('ok')
