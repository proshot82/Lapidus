# art/blender/room.py — фон квартиры в Blender: кладка с объёмной плиткой и скруглённой кромкой, тени на стене,
# решётки сливов, стальной стояк с вентилем, кронштейны и трубы сети с выходами единого стандарта стыка.
# Плоские слои (краска стены, шахты сливов, маска полосы плитки) готовит art/room_prep.py; здесь они — текстуры
# в экранных координатах. Рендер 1920×1080, как фон в игре; лицевая плоскость кладки — y = -0.5, задняя стена — y = +0.55.
# Запуск: blender -b -P art/blender/room.py -- build/room/lvl01.json <выход.png>
import bpy, bmesh, math, sys, os, json, subprocess
from mathutils import Vector, Matrix

argv = sys.argv[sys.argv.index('--') + 1:]
D = json.load(open(argv[0]))
OUT = argv[1]
BASE = argv[0][:-5]
C = D['c']
LIM = .47
R_BODY, R_SOCK, R_THR = .18, .23, .15
R_RISER = .22


def lin(c):
    c = c.lstrip('#'); v = [int(c[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return tuple(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in v)


# ---------- сцена

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
sc.render.engine = 'BLENDER_EEVEE'
sc.render.resolution_x, sc.render.resolution_y = 1920, 1080
sc.view_settings.view_transform = 'Standard'
ee = sc.eevee
ee.use_soft_shadows = True
ee.shadow_cascade_size = '4096'
ee.use_gtao = True
ee.gtao_distance = .6
ee.gtao_factor = 1.4
sc.render.use_freestyle = True
sc.render.line_thickness_mode = 'ABSOLUTE'
sc.render.line_thickness = 1.0
for nm in ('walls', 'threads', 'proxy'):
    sc.collection.children.link(bpy.data.collections.new(nm))
vl = sc.view_layers[0]
fs = vl.freestyle_settings
fs.crease_angle = math.radians(120)


def lineset(name, thick, coll, exclude=False):
    ls = fs.linesets.new(name)
    ls.select_by_visibility = True
    ls.select_by_edge_types = True
    ls.select_by_collection = True
    ls.collection = bpy.data.collections[coll]
    ls.collection_negation = 'EXCLUSIVE' if exclude else 'INCLUSIVE'
    ls.select_silhouette = True
    ls.select_border = False
    ls.select_crease = False
    ls.select_external_contour = True
    ls.linestyle = bpy.data.linestyles.new(name)
    ls.linestyle.color = lin('#2B2118')
    ls.linestyle.thickness = thick
    return ls


lineset('walls', max(5.0, .055 * C), 'walls')
lineset('parts', 4.5 * C / 240 * 1.25, 'walls', exclude=True)
for ls in fs.linesets:
    if ls.linestyle is None:
        ls.linestyle = bpy.data.linestyles.new('x')

cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam'))
cam.data.type = 'ORTHO'
cam.data.ortho_scale = 1920 / C
cam.location = ((960 - D['ox']) / C, -20, -(540 - D['oy']) / C)
cam.rotation_euler = (math.radians(90), 0, 0)
sc.collection.objects.link(cam)
sc.camera = cam
sun = bpy.data.objects.new('sun', bpy.data.lights.new('sun', 'SUN'))
sun.data.energy = 3.0
sun.data.angle = math.radians(6)
# свет сверху-слева и чуть спереди: тень кладки ложится на стену вправо-вниз (как прежняя тень .10c, .15c)
sun.rotation_euler = Vector((0, 0, -1)).rotation_difference(Vector((.42, .80, -.62)).normalized()).to_euler()
sc.collection.objects.link(sun)
sc.world = bpy.data.worlds.new('w')
sc.world.use_nodes = True
sc.world.node_tree.nodes['Background'].inputs[1].default_value = 0.0


# ---------- материалы

def toon_factor(nt, steps=((0, .62), (.18, .84), (.55, 1.0), (.92, 1.16)), normal=None):
    dif = nt.nodes.new('ShaderNodeBsdfDiffuse')
    if normal is not None:
        nt.links.new(normal, dif.inputs['Normal'])
    s2r = nt.nodes.new('ShaderNodeShaderToRGB')
    bw = nt.nodes.new('ShaderNodeRGBToBW')
    ramp = nt.nodes.new('ShaderNodeValToRGB')
    cr = ramp.color_ramp
    cr.interpolation = 'CONSTANT'
    cr.elements[0].position, cr.elements[0].color = steps[0][0], (steps[0][1],) * 3 + (1,)
    cr.elements[1].position, cr.elements[1].color = steps[1][0], (steps[1][1],) * 3 + (1,)
    for p, v in steps[2:]:
        e = cr.elements.new(p); e.color = (v,) * 3 + (1,)
    nt.links.new(dif.outputs[0], s2r.inputs[0])
    nt.links.new(s2r.outputs[0], bw.inputs[0])
    nt.links.new(bw.outputs[0], ramp.inputs[0])
    return ramp.outputs[0]


def emit(nt, col):
    out = nt.nodes.new('ShaderNodeOutputMaterial')
    em = nt.nodes.new('ShaderNodeEmission')
    nt.links.new(col, em.inputs[0])
    nt.links.new(em.outputs[0], out.inputs[0])


def mul(nt, a, b):
    m = nt.nodes.new('ShaderNodeMixRGB'); m.blend_type = 'MULTIPLY'; m.inputs[0].default_value = 1
    nt.links.new(a, m.inputs[1])
    if isinstance(b, tuple):
        m.inputs[2].default_value = b
    else:
        nt.links.new(b, m.inputs[2])
    return m.outputs[0]


def screen_image(nt, path):
    tc = nt.nodes.new('ShaderNodeTexCoord')
    im = nt.nodes.new('ShaderNodeTexImage')
    im.image = bpy.data.images.load(path)
    im.extension = 'EXTEND'
    nt.links.new(tc.outputs['Window'], im.inputs[0])
    return im.outputs[0]


def new_mat(name):
    m = bpy.data.materials.new(name); m.use_nodes = True; m.node_tree.nodes.clear()
    return m, m.node_tree


def toon(name, dark, mid, light, spec):
    m, nt = new_mat(name)
    dif = nt.nodes.new('ShaderNodeBsdfDiffuse')
    s2r = nt.nodes.new('ShaderNodeShaderToRGB')
    ramp = nt.nodes.new('ShaderNodeValToRGB')
    cr = ramp.color_ramp
    cr.interpolation = 'CONSTANT'
    cr.elements[0].position, cr.elements[0].color = 0.0, (*lin(dark), 1)
    cr.elements[1].position, cr.elements[1].color = 0.18, (*lin(mid), 1)
    e = cr.elements.new(0.55); e.color = (*lin(light), 1)
    e = cr.elements.new(0.92); e.color = (*lin(spec), 1)
    nt.links.new(dif.outputs[0], s2r.inputs[0])
    nt.links.new(s2r.outputs[0], ramp.inputs[0])
    emit(nt, ramp.outputs[0])
    return m


# задняя стена: краска из слоя room_prep × тень (две ступени)
m_back, nt = new_mat('back')
paint = screen_image(nt, BASE + '_paint.png')
emit(nt, mul(nt, paint, toon_factor(nt, ((0, .66), (.30, 1.0)))))

# кладка: плитка в полосе вдоль комнаты (маска band), дальше бетон; плитка — Brick Texture по (x, z) с рельефом швов
m_wall, nt = new_mat('wall')
geo = nt.nodes.new('ShaderNodeNewGeometry')
sep = nt.nodes.new('ShaderNodeSeparateXYZ'); nt.links.new(geo.outputs['Position'], sep.inputs[0])
com = nt.nodes.new('ShaderNodeCombineXYZ'); nt.links.new(sep.outputs[0], com.inputs[0]); nt.links.new(sep.outputs[2], com.inputs[1])
base, grout, hi = D['tile']


def mth(op, a, b=None):
    m = nt.nodes.new('ShaderNodeMath'); m.operation = op
    for i, v in enumerate((a, b)):
        if v is None:
            continue
        if isinstance(v, (int, float)):
            m.inputs[i].default_value = v
        else:
            nt.links.new(v, m.inputs[i])
    return m.outputs[0]


def mixc(fac, c0, c1):
    m = nt.nodes.new('ShaderNodeMixRGB')
    nt.links.new(fac, m.inputs[0])
    for i, c in ((1, c0), (2, c1)):
        if isinstance(c, tuple):
            m.inputs[i].default_value = c
        else:
            nt.links.new(c, m.inputs[i])
    return m.outputs[0]


# плитка полклетки: u, v — положение внутри плитки; шов, светлая фаска сверху-слева, тёмная снизу-справа
u = mth('FRACT', mth('MULTIPLY', sep.outputs[0], 2))
v = mth('FRACT', mth('MULTIPLY', sep.outputs[2], 2))
ml = mth('MINIMUM', u, mth('SUBTRACT', 1, v))
md = mth('MINIMUM', mth('SUBTRACT', 1, u), v)
e = mth('MINIMUM', ml, md)
face = (*lin(base), 1)
lightc = tuple(min(1, x * 1.0) for x in lin(hi)) + (1,)
darkc = tuple(x * .72 for x in lin(base)) + (1,)
bev = mixc(mth('LESS_THAN', ml, md), darkc, lightc)
tile_col = mixc(mth('LESS_THAN', e, .085), face, bev)
tile_col = mixc(mth('LESS_THAN', e, .028), tile_col, (*lin(grout), 1))
noi = nt.nodes.new('ShaderNodeTexNoise'); noi.inputs['Scale'].default_value = 26; noi.inputs['Detail'].default_value = 4
nt.links.new(com.outputs[0], noi.inputs['Vector'])
cramp = nt.nodes.new('ShaderNodeValToRGB')
cramp.color_ramp.elements[0].color = (*lin('#8C8476'), 1); cramp.color_ramp.elements[1].color = (*lin('#A39A8B'), 1)
cramp.color_ramp.elements[0].position, cramp.color_ramp.elements[1].position = .35, .65
nt.links.new(noi.outputs['Fac'], cramp.inputs[0])
conc_col = mul(nt, cramp.outputs[0], toon_factor(nt))
band = screen_image(nt, BASE + '_band.png')
bw = nt.nodes.new('ShaderNodeRGBToBW'); nt.links.new(band, bw.inputs[0])
mix = nt.nodes.new('ShaderNodeMixRGB'); nt.links.new(bw.outputs[0], mix.inputs[0])
nt.links.new(conc_col, mix.inputs[1]); nt.links.new(tile_col, mix.inputs[2])
emit(nt, mix.outputs[0])

STEEL = toon('steel', '#3E454C', '#7C868F', '#B3BCC5', '#EEF2F6')
IRON = toon('iron', '#2C3136', '#4F5760', '#7E8892', '#C9D0D7')
GRATE = toon('grate', '#22272C', '#3C434A', '#5C646C', '#8A939B')
RED = toon('red', '#7E2116', '#C83E2C', '#E2604B', '#F59A83')
BRASS = toon('brass', '#7A5414', '#C9962E', '#EBC260', '#FFF3C2')

# ржавчина на стояке: шум по координатам → пятна поверх железа
m_riser, nt = new_mat('riser')
geo = nt.nodes.new('ShaderNodeNewGeometry')
noi = nt.nodes.new('ShaderNodeTexNoise'); noi.inputs['Scale'].default_value = 3.2; noi.inputs['Detail'].default_value = 3
nt.links.new(geo.outputs['Position'], noi.inputs['Vector'])
rr = nt.nodes.new('ShaderNodeValToRGB'); rr.color_ramp.interpolation = 'CONSTANT'
rr.color_ramp.elements[0].color = (*lin('#6E7781'), 1)
rr.color_ramp.elements[1].position = .62; rr.color_ramp.elements[1].color = (*lin('#8E5A36'), 1)
nt.links.new(noi.outputs['Fac'], rr.inputs[0])
emit(nt, mul(nt, rr.outputs[0], toon_factor(nt, ((0, .55), (.18, .85), (.55, 1.1), (.92, 1.6)))))


def link(o, coll=None):
    for cl in list(o.users_collection):
        cl.objects.unlink(o)
    (bpy.data.collections[coll] if coll else sc.collection).objects.link(o)
    return o


def finish(o, mat, smooth=True, coll=None):
    bpy.context.view_layer.objects.active = o
    if smooth and o.type == 'MESH':
        for p in o.data.polygons: p.use_smooth = True
    o.data.materials.append(mat)
    return link(o, coll)


# ---------- кладка

cu = bpy.data.curves.new('walls', 'CURVE')
cu.dimensions = '2D'
cu.fill_mode = 'BOTH'
cu.extrude = .5
cu.bevel_depth = 0  # скругление кромки даёт полосу и линии там, где углы стен касаются по диагонали
cu.resolution_u = 1
L, T = cam.location.x - 960 / C - 1, -cam.location.z - 540 / C - 1
Rr, B = cam.location.x + 960 / C + 1, -cam.location.z + 540 / C + 1
for pts in [[(L, T), (Rr, T), (Rr, B), (L, B)]] + D['loops']:
    sp = cu.splines.new('POLY')
    sp.points.add(len(pts) - 1)
    for p, (x, y) in zip(sp.points, pts):
        p.co = (x, -y, 0, 1)
    sp.use_cyclic_u = True
walls = bpy.data.objects.new('walls', cu)
walls.rotation_euler = (math.radians(90), 0, 0)
walls.data.materials.append(m_wall)
link(walls, 'walls')

bpy.ops.mesh.primitive_plane_add(size=1, location=(cam.location.x, .55, cam.location.z), rotation=(math.radians(90), 0, 0))
back = bpy.context.object
back.scale = (1920 / C + 4, 1080 / C + 4, 1)
finish(back, m_back, smooth=False, coll='walls')


# ---------- детали сети

def cyl(r, a, b, mat, verts=40, coll=None):
    a, b = Vector(a), Vector(b)
    d = b - a
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=d.length)
    o = bpy.context.object
    o.rotation_mode = 'QUATERNION'
    o.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(d.normalized())
    o.location = (a + b) / 2
    bpy.ops.object.transform_apply(location=True, rotation=True)
    return finish(o, mat, coll=coll)


def sphere(r, p, mat, scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=p, segments=32, ring_count=16)
    o = bpy.context.object; o.scale = scale
    bpy.ops.object.transform_apply(scale=True)
    return finish(o, mat)


DIRV = {'right': (1, 0), 'left': (-1, 0), 'up': (0, 1), 'down': (0, -1)}
Y0 = -.85  # ось труб сети — перед кладкой: стояк идёт поверх стены, как прежде


def P(cx, cz, d, t):
    """Точка на оси от центра (cx, cz) в сторону d на расстоянии t."""
    return (cx + DIRV[d][0] * t, Y0, cz + DIRV[d][1] * t)


def port(cx, cz, d, th, start):
    """Выход стандарта стыка (сталь сети): наружная резьба Ø0.30 или раструб Ø0.46 до края клетки."""
    if th == 'N':
        cyl(R_THR * 1.06, P(cx, cz, d, start), P(cx, cz, d, LIM), STEEL, coll='proxy')
        cyl(R_THR * .9, P(cx, cz, d, start), P(cx, cz, d, LIM), STEEL, coll='threads')
        t = start + .025
        while t < LIM - .015:
            bpy.ops.mesh.primitive_torus_add(major_radius=R_THR * .92, minor_radius=R_THR * .16, major_segments=48, minor_segments=8)
            o = bpy.context.object
            o.rotation_mode = 'QUATERNION'
            o.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(Vector((DIRV[d][0], 0, DIRV[d][1])))
            o.location = P(cx, cz, d, t)
            bpy.ops.object.transform_apply(location=True, rotation=True)
            finish(o, STEEL, coll='threads')
            t += .05
    else:
        cyl(R_SOCK, P(cx, cz, d, start), P(cx, cz, d, LIM), STEEL)


def arm(cx, cz, d, t0, t1, r=R_BODY * .97, mat=None):
    cyl(r, P(cx, cz, d, t0), P(cx, cz, d, t1), mat or STEEL)


for ob in D['objects']:
    cx, cz = ob['x'], -ob['y']
    ports = ob['ports']
    if ob['kind'] == 'source':
        top, bot = -ob['top'], -ob['bot']
        t1 = top + (.06 if ob.get('capT') else .3)
        b1 = bot - (.06 if ob.get('capB') else .3)
        cyl(R_RISER, (cx, Y0, t1), (cx, Y0, b1), m_riser, verts=48)
        for zz, cap, sg_ in ((t1, ob.get('capT'), 1), (b1, ob.get('capB'), -1)):
            if cap:                                                # чугунная заглушка на конце стояка
                cyl(.27, (cx, Y0, zz - sg_ * .10), (cx, Y0, zz + sg_ * .02), IRON, verts=48)
                sphere(.20, (cx, Y0, zz + sg_ * .02), IRON, (1, 1, .45))
        for yy in (-.50, .50):                                     # фланцы с болтами (у заглушки — не нужен)
            if (yy > 0 and ob.get('capT') and t1 - (cz + yy) < .2) or (yy < 0 and ob.get('capB') and (cz + yy) - b1 < .2):
                continue
            cyl(.31, (cx, Y0, cz + yy - .06), (cx, Y0, cz + yy + .06), IRON, verts=48)
            for bx in (-.22, .22):
                sphere(.035, (cx + bx, Y0 - .29, cz + yy), STEEL, (1, .6, 1))
        sphere(.27, (cx, Y0, cz), IRON, (1, 1, 1.15))              # корпус вентиля
        for d, th in ports.items():
            arm(cx, cz, d, .15, .30)
            port(cx, cz, d, th, .26)
        cyl(.04, (cx, Y0 - .2, cz), (cx, Y0 - .5, cz), STEEL)      # шток к маховику
        wy = Y0 - .52
        bpy.ops.mesh.primitive_torus_add(major_radius=.20, minor_radius=.034, major_segments=64, minor_segments=12,
                                         location=(cx, wy, cz), rotation=(math.radians(90), 0, 0))
        finish(bpy.context.object, RED)
        for k in range(4):
            a = math.pi / 4 + k * math.pi / 2
            cyl(.024, (cx, wy, cz), (cx + math.cos(a) * .19, wy, cz + math.sin(a) * .19), RED, verts=16)
        sphere(.055, (cx, wy - .02, cz), BRASS)
    elif ob['kind'] == 'stub':
        d, th = list(ports.items())[0]
        m = ob['mount']
        arm(cx, cz, m, 0, .40)
        mx, mz = cx + DIRV[m][0] * .44, cz + DIRV[m][1] * .44     # пятка кронштейна на стене
        if DIRV[m][0]:
            bpy.ops.mesh.primitive_cube_add(size=1, location=(mx, Y0, mz)); o = bpy.context.object; o.scale = (.10, .5, .62)
        else:
            bpy.ops.mesh.primitive_cube_add(size=1, location=(mx, Y0, mz)); o = bpy.context.object; o.scale = (.62, .5, .10)
        bpy.ops.object.transform_apply(scale=True)
        md = o.modifiers.new('b', 'BEVEL'); md.width = .025; md.segments = 3
        bpy.ops.object.modifier_apply(modifier='b')
        finish(o, IRON)
        for s in (-.21, .21):
            p = (mx + (0 if DIRV[m][0] else s), Y0 - .26, mz + (s if DIRV[m][0] else 0))
            sphere(.03, p, STEEL, (1, .6, 1))
        if m != {'up': 'down', 'down': 'up', 'left': 'right', 'right': 'left'}[d]:
            sphere(.21, (cx, Y0, cz), STEEL)
        arm(cx, cz, d, 0, .30)
        port(cx, cz, d, th, .26)
    elif ob['kind'] == 'pipe':
        sphere(.22, (cx, Y0, cz), STEEL)
        for d, th in ports.items():
            arm(cx, cz, d, 0, .30)
            port(cx, cz, d, th, .26)

# решётки сливов: кольцо в перспективе и прутья (вид чуть сверху на пол)
for dx, dy in D['drains']:
    gx, gz = dx, -(dy - .5) - .08
    before = set(sc.objects)
    bpy.ops.mesh.primitive_torus_add(major_radius=.44, minor_radius=.035, major_segments=64, minor_segments=10)
    finish(bpy.context.object, GRATE)
    for k in (-.30, -.15, 0, .15, .30):
        h = math.sqrt(.44 ** 2 - k ** 2)
        cyl(.022, (k, -h, 0), (k, h, 0), GRATE, verts=12)
    for o in [o for o in sc.objects if o not in before]:
        o.data.transform(Matrix.Translation((gx, -.25, gz)) @ Matrix.Rotation(math.radians(10), 4, 'X'))
        o.data.update()

# ---------- два прохода: всё с обводкой (резьба — гладким заместителем), затем резьба без обводки
th, px = bpy.data.collections['threads'], bpy.data.collections['proxy']
a, b = OUT[:-4] + '_a.png', OUT[:-4] + '_b.png'
th.hide_render, px.hide_render = True, False
sc.render.filepath = a
bpy.ops.render.render(write_still=True)
if th.objects:
    for o in sc.objects:
        if o.type in ('MESH', 'CURVE') and th not in o.users_collection:
            o.hide_render = True
    th.hide_render = False
    sc.render.use_freestyle = False
    sc.render.film_transparent = True
    sc.render.filepath = b
    bpy.ops.render.render(write_still=True)
    subprocess.run(['convert', a, b, '-composite', OUT], check=True)
else:
    os.replace(a, OUT)
print('ROOM', OUT)
