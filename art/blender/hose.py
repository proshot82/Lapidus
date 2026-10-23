# art/blender/hose.py — текстура гофры тела Лапидуса: один шаг ребра, бесшовно по длине (u), поперёк — вся ширина
# с обводкой (v). Движок натягивает её лентой вдоль тела (game/board.lua drawLapidus), шаг ребра растягивается с длиной.
# Рендер трёх шагов, в файл — средний (иначе обводка Freestyle рвётся на краях кадра).
# Запуск: blender -b -P art/blender/hose.py -- assets/gfx/hose_tex.png
import bpy, bmesh, math, sys, os, subprocess
from mathutils import Vector

OUT = sys.argv[sys.argv.index('--') + 1]
PX = 128             # пикселей на шаг ребра
H = 512              # пикселей поперёк (ширина ленты в движке = 0.56 + 0.09 клетки)
P = 1.0              # шаг ребра, ед. Blender
SPAN = 4.0 * P       # поперёк кадра (ортокамера: 3 шага × 128 px по ширине = 4 шага × 512 px по высоте)
A_K = .12
R0 = SPAN * .5 * (.56 / .65) / (1 + A_K)  # гребни касаются края ленты без обводки (0.56 из 0.65)
A = A_K * R0         # глубина гофры

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
sc.render.engine = 'BLENDER_EEVEE'
sc.render.resolution_x, sc.render.resolution_y = 3 * PX, H
sc.render.film_transparent = True
sc.view_settings.view_transform = 'Standard'
sc.render.use_freestyle = False  # обводка — тёмная подложка ленты (иначе Freestyle обводит каждый гребень)
sc.render.line_thickness_mode = 'ABSOLUTE'
sc.render.line_thickness = 1.0
vl = sc.view_layers[0]
ls = vl.freestyle_settings.linesets.new('ol')
ls.select_by_visibility = True
ls.select_by_edge_types = True
ls.select_silhouette = False
ls.select_border = False
ls.select_crease = False
ls.select_external_contour = True
ls.linestyle = bpy.data.linestyles.new('ol')
ls.linestyle.color = (0.024, 0.016, 0.010)
ls.linestyle.thickness = H * .045 / .65 * 2  # линия по контуру; наружная половина — обводка ленты
for other in vl.freestyle_settings.linesets:
    if other.linestyle is None:
        other.linestyle = ls.linestyle
cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam'))
cam.data.type = 'ORTHO'
cam.data.ortho_scale = SPAN              # по большей стороне кадра (высота)
cam.location = (0, -10, 0)
cam.rotation_euler = (math.radians(90), 0, 0)
sc.collection.objects.link(cam)
sc.camera = cam
sun = bpy.data.objects.new('sun', bpy.data.lights.new('sun', 'SUN'))
sun.data.energy = 3.0
# свет спереди и вдоль шланга: скаты рёбер светлый/тёмный (рёбра читаются), поперёк — симметрично (лента не «переворачивается»)
sun.rotation_euler = Vector((0, 0, -1)).rotation_difference(Vector((.62, .78, 0)).normalized()).to_euler()
sc.collection.objects.link(sun)
sc.world = bpy.data.worlds.new('w')
sc.world.use_nodes = True
sc.world.node_tree.nodes['Background'].inputs[1].default_value = 0.0


def lin(c):
    c = c.lstrip('#'); v = [int(c[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return tuple(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in v)


m = bpy.data.materials.new('hose'); m.use_nodes = True
nt = m.node_tree; nt.nodes.clear()
out = nt.nodes.new('ShaderNodeOutputMaterial')
dif = nt.nodes.new('ShaderNodeBsdfDiffuse')
s2r = nt.nodes.new('ShaderNodeShaderToRGB')
ramp = nt.nodes.new('ShaderNodeValToRGB')
emi = nt.nodes.new('ShaderNodeEmission')
cr = ramp.color_ramp
cr.interpolation = 'CONSTANT'
cr.elements[0].position, cr.elements[0].color = 0.0, (*lin('#9C927A'), 1)
cr.elements[1].position, cr.elements[1].color = 0.25, (*lin('#C9C0AA'), 1)
e = cr.elements.new(0.55); e.color = (*lin('#E8E2D2'), 1)
e = cr.elements.new(0.80); e.color = (*lin('#F8F5EC'), 1)
nt.links.new(dif.outputs[0], s2r.inputs[0])
nt.links.new(s2r.outputs[0], ramp.inputs[0])
nt.links.new(ramp.outputs[0], emi.inputs[0])
nt.links.new(emi.outputs[0], out.inputs[0])

# гофра: поверхность вращения профиля r(x) = R0 + A·(1 − |cos(πx/P)|^0.6) — гребни широкие, впадины узкие
NX, NA = 400, 96
x0, x1 = -3 * P, 3 * P
bm = bmesh.new()
rings = []
for i in range(NX + 1):
    x = x0 + (x1 - x0) * i / NX
    r = R0 + A * (1 - abs(math.cos(math.pi * x / P)) ** .6)
    rings.append([bm.verts.new((x, r * math.cos(2 * math.pi * j / NA), r * math.sin(2 * math.pi * j / NA))) for j in range(NA)])
for i in range(NX):
    for j in range(NA):
        bm.faces.new((rings[i][j], rings[i][(j + 1) % NA], rings[i + 1][(j + 1) % NA], rings[i + 1][j]))
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
me = bpy.data.meshes.new('hose'); bm.to_mesh(me); bm.free()
for p in me.polygons: p.use_smooth = True
o = bpy.data.objects.new('hose', me); o.data.materials.append(m)
sc.collection.objects.link(o)

tmp = OUT[:-4] + '_3.png'
sc.render.filepath = tmp
bpy.ops.render.render(write_still=True)
# средний шаг — бесшовный кусок; верх и низ кадра — край ленты
subprocess.run(['convert', '-size', '%dx%d' % (PX, H), 'xc:#2B2118', '(', tmp, '-crop', '%dx%d+%d+0' % (PX, H, PX), '+repage', ')',
                '-composite', '-depth', '8', '-define', 'png:exclude-chunks=date', 'PNG32:' + OUT], check=True)  # 8 бит: WebGL не берёт rgba16
os.remove(tmp)
print('HOSE', OUT)
