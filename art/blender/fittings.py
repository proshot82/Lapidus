# art/blender/fittings.py — латунные фитинги: 3D-форма по настоящим пропорциям, рендер в 2D-мультяшном виде
# (плоская заливка в три ступени, толстая тёмная обводка Freestyle, ортокамера строго сбоку, прозрачный фон).
# Запуск: blender -b -P art/blender/fittings.py -- <выходная папка> [имена...]
# Единица длины = клетка поля; деталь занимает ±0.47 клетки. Холст 480×480 = 2 клетки (как спрайты art/export.py).
import bpy, bmesh, math, sys, os
from mathutils import Vector, Matrix

argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
OUT = argv[0] if argv else '/tmp/fit'
ONLY = set(argv[1:]) - {'levels'}
os.makedirs(OUT, exist_ok=True)

LIM = .47
R_BODY, R_SOCK, R_THR, R_HEX = .15, .19, .12, .21


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = 'BLENDER_EEVEE'
    sc.render.resolution_x = sc.render.resolution_y = 480
    sc.render.film_transparent = True
    sc.view_settings.view_transform = 'Standard'
    sc.render.use_freestyle = True
    sc.render.line_thickness_mode = 'ABSOLUTE'
    sc.render.line_thickness = 3.2
    vl = sc.view_layers[0]
    ls = vl.freestyle_settings.linesets.new('ol')
    ls.select_by_visibility = True
    ls.select_by_edge_types = True
    ls.select_silhouette = True
    ls.select_border = False
    ls.select_crease = False
    ls.select_external_contour = True
    for nm in ('threads', 'proxy'):
        sc.collection.children.link(bpy.data.collections.new(nm))
    if ls.linestyle is None:
        ls.linestyle = bpy.data.linestyles.new('ol')
    ls.linestyle.color = (0.043, 0.027, 0.016)
    ls.linestyle.thickness = 3.2
    vl.freestyle_settings.crease_angle = math.radians(120)
    for other in vl.freestyle_settings.linesets:
        if other.linestyle is None:
            other.linestyle = ls.linestyle
    cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam'))
    cam.data.type = 'ORTHO'
    cam.data.ortho_scale = 2.0
    cam.location = (0, -10, 0)
    cam.rotation_euler = (math.radians(90), 0, 0)
    sc.collection.objects.link(cam)
    sc.camera = cam
    sun = bpy.data.objects.new('sun', bpy.data.lights.new('sun', 'SUN'))
    sun.data.energy = 3.0
    sun.rotation_euler = (math.radians(50), math.radians(-35), math.radians(-25))  # свет сверху-слева, как во всём арте
    sc.collection.objects.link(sun)
    sc.world = bpy.data.worlds.new('w')
    sc.world.use_nodes = True
    sc.world.node_tree.nodes['Background'].inputs[1].default_value = 0.0


def toon(name, dark, mid, light, spec=(1, 0.97, 0.85)):
    """Мультяшный материал: освещённость → ступенчатая палитра (тень / основной / свет / блик)."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.clear()
    out = nt.nodes.new('ShaderNodeOutputMaterial')
    dif = nt.nodes.new('ShaderNodeBsdfDiffuse')
    s2r = nt.nodes.new('ShaderNodeShaderToRGB')
    ramp = nt.nodes.new('ShaderNodeValToRGB')
    emi = nt.nodes.new('ShaderNodeEmission')
    cr = ramp.color_ramp
    cr.interpolation = 'CONSTANT'
    cr.elements[0].position, cr.elements[0].color = 0.0, (*dark, 1)
    cr.elements[1].position, cr.elements[1].color = 0.18, (*mid, 1)
    e = cr.elements.new(0.55); e.color = (*light, 1)
    e = cr.elements.new(0.92); e.color = (*spec, 1)
    nt.links.new(dif.outputs[0], s2r.inputs[0])
    nt.links.new(s2r.outputs[0], ramp.inputs[0])
    nt.links.new(ramp.outputs[0], emi.inputs[0])
    nt.links.new(emi.outputs[0], out.inputs[0])
    return m


def lin(c):  # sRGB hex → линейный
    c = c.lstrip('#'); v = [int(c[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return tuple(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in v)


BRASS = None
DARKM = None


def mats():
    global BRASS, DARKM
    BRASS = toon('brass', lin('#7A5414'), lin('#C9962E'), lin('#EBC260'), lin('#FFF3C2'))
    DARKM = toon('bore', lin('#1E150B'), lin('#2E2112'), lin('#3B2B17'), lin('#4A3720'))


def cyl(r, x0, x1, axis='X', verts=48, mat=None):
    """Цилиндр вдоль оси от x0 до x1 (в долях клетки)."""
    L = x1 - x0
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=abs(L), end_fill_type='NOTHING')  # торцы сбоку не видны, а их рёбра дают обводке лишние чёрточки
    o = bpy.context.object
    c = (x0 + x1) / 2
    if axis == 'X':
        o.rotation_euler = (0, math.radians(90), 0); o.location = (c, 0, 0)
    else:
        o.location = (0, 0, c)
    bpy.ops.object.transform_apply(location=True, rotation=True)
    bpy.ops.object.shade_smooth()
    o.data.materials.append(mat or BRASS)
    return o


def hexp(r, x0, x1, mat=None):
    o = cyl(r, x0, x1, verts=6, mat=mat)
    bpy.ops.object.shade_flat()
    o.rotation_euler = (math.radians(30), 0, 0)
    bpy.ops.object.transform_apply(rotation=True)
    return o


def to_coll(o, name):
    for c in list(o.users_collection):
        c.objects.unlink(o)
    bpy.data.collections[name].objects.link(o)


def thread(x0, x1, r=R_THR, pitch=.05):
    """Наружная резьба: стержень и кольца-витки — рисуются вторым проходом без обводки; контур даёт гладкий
    заместитель (первый проход), иначе обводка Freestyle на каждом витке превращает резьбу в чёрный брусок."""
    to_coll(cyl(r * 1.06, x0, x1), 'proxy')
    to_coll(cyl(r * .9, x0, x1), 'threads')
    x = x0 + pitch / 2
    while x < x1 - pitch / 3:
        bpy.ops.mesh.primitive_torus_add(major_radius=r * .92, minor_radius=r * .16, major_segments=48, minor_segments=8)
        t = bpy.context.object
        t.rotation_euler = (0, math.radians(90), 0); t.location = (x, 0, 0)
        bpy.ops.object.transform_apply(location=True, rotation=True)
        to_coll(t, 'threads')
        bpy.ops.object.shade_smooth()
        t.data.materials.append(BRASS)
        x += pitch
    to_coll(cyl(r * .78, x1 - .015, x1 + .0), 'threads')  # фаска на торце


def socket(x0, x1):
    """Раструб с внутренней резьбой: шире тела, буртик на торце."""
    cyl(R_SOCK, x0, x1 - .04)
    cyl(R_SOCK * 1.06, x1 - .04, x1)


def port(dirv, th, start):
    """Выход в сторону dirv (вектор), начинается на расстоянии start от центра, кончается на LIM."""
    before = set(bpy.context.scene.objects)
    if th == 'N':
        thread(start, LIM)
    else:
        socket(start, LIM)
    new = [o for o in bpy.context.scene.objects if o not in before]
    ang = math.atan2(dirv[1], dirv[0])  # поворот в плоскости XZ (вид сбоку)
    for o in new:
        o.data.transform(Matrix.Rotation(-ang, 4, 'Y'))
        o.data.update()


DIRS = {'right': (1, 0), 'left': (-1, 0), 'up': (0, 1), 'down': (0, -1)}


def arm(dirv, x1):
    o = cyl(R_BODY, 0, x1)
    o.data.transform(Matrix.Rotation(-math.atan2(dirv[1], dirv[0]), 4, 'Y'))


def elbow(d1, d2):
    """Гнутое колено: четверть тора между двумя выходами + прямые хвосты."""
    v1, v2 = Vector((DIRS[d1][0], 0, DIRS[d1][1])), Vector((DIRS[d2][0], 0, DIRS[d2][1]))
    rb = .17
    corner = (v1 + v2) * rb  # центр изгиба
    bpy.ops.mesh.primitive_torus_add(major_radius=rb, minor_radius=R_BODY, major_segments=64, minor_segments=32)
    t = bpy.context.object
    t.rotation_euler = (math.radians(90), 0, 0)
    t.location = corner
    bpy.ops.object.transform_apply(location=True, rotation=True)
    # оставить только четверть тора, обращённую к центру клетки
    bm = bmesh.new(); bm.from_mesh(t.data)
    kill = [v for v in bm.verts if (v.co - corner).dot(v1) > 1e-4 or (v.co - corner).dot(v2) > 1e-4]
    bmesh.ops.delete(bm, geom=kill, context='VERTS'); bm.to_mesh(t.data); bm.free()
    bpy.ops.object.shade_smooth()
    t.data.materials.append(BRASS)
    for d in (d1, d2):
        o = cyl(R_BODY, rb - .005, .30)
        dv = DIRS[d]; o.data.transform(Matrix.Rotation(-math.atan2(dv[1], dv[0]), 4, 'Y'))


def build(ports):
    ds = list(ports)
    if len(ds) == 2 and DIRS[ds[0]][0] == -DIRS[ds[1]][0] and DIRS[ds[0]][1] == -DIRS[ds[1]][1]:
        a, b = ds
        if ports[a] == 'V' and ports[b] == 'V':      # муфта
            cyl(R_BODY + .01, -.32, .32)
            for d in ds: port(DIRS[d], 'V', .24)
        else:                                          # ниппель / переходник
            o = hexp(R_HEX, -.10, .10)
            if a in ('up', 'down'):
                o.data.transform(Matrix.Rotation(math.radians(90), 4, 'Y'))
            for d in ds: port(DIRS[d], ports[d], .09 if ports[d] == 'N' else .12)
    elif len(ds) == 2:                                 # угольник
        elbow(*ds)
        for d in ds: port(DIRS[d], ports[d], .26)
    elif len(ds) == 1:                                 # заглушка
        d = ds[0]
        o = hexp(R_HEX, -.16, .06)
        dv = DIRS[d]; o.data.transform(Matrix.Rotation(-math.atan2(dv[1], dv[0]), 4, 'Y'))
        port(dv, ports[d], .06 if ports[d] == 'N' else .02)
    else:                                              # тройник
        for d in ds: arm(DIRS[d], .28)
        bpy.ops.mesh.primitive_uv_sphere_add(radius=R_BODY * 1.12, segments=48, ring_count=24)
        bpy.ops.object.shade_smooth(); bpy.context.object.data.materials.append(BRASS)
        for d in ds: port(DIRS[d], ports[d], .26)


def level_sigs():
    import re, glob
    root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    out = {}
    for f in sorted(glob.glob(os.path.join(root, 'levels', '[0-9][0-9].lua'))):
        for m in re.finditer(r'kind = "fitting".*?ports = \{([^}]*)\}', open(f, encoding='utf-8').read()):
            ports = dict(re.findall(r'(up|right|down|left) = "([NV])"', m.group(1)))
            sig = ''.join(d[0] + ports[d] for d in ('up', 'right', 'down', 'left') if d in ports)
            out['fit_' + sig] = ports
    return out


SET = level_sigs() if 'levels' in argv else {
    'fit_rVlV': {'right': 'V', 'left': 'V'},
    'fit_rNlN': {'right': 'N', 'left': 'N'},
    'fit_rNlV': {'right': 'N', 'left': 'V'},
    'fit_uNlV': {'up': 'N', 'left': 'V'},
    'fit_uVdVlN': {'up': 'V', 'down': 'V', 'left': 'N'},
    'fit_rN': {'right': 'N'},
    'fit_rVdV': {'right': 'V', 'down': 'V'},
    'fit_uNdN': {'up': 'N', 'down': 'N'},
}
for name, ports in SET.items():
    if ONLY and name not in ONLY:
        continue
    reset(); mats(); build(ports)
    sc = bpy.context.scene
    th, px = bpy.data.collections['threads'], bpy.data.collections['proxy']
    a, b = os.path.join(OUT, '_a.png'), os.path.join(OUT, '_b.png')
    # проход A: всё с обводкой, резьба — гладким заместителем
    th.hide_render, px.hide_render = True, False
    sc.render.use_freestyle = True
    sc.render.filepath = a; bpy.ops.render.render(write_still=True)
    # проход B: только резьба, без обводки
    others = [o for o in sc.objects if o.type == 'MESH' and th not in o.users_collection]
    for o in others: o.hide_render = True
    th.hide_render = False
    sc.render.use_freestyle = False
    sc.render.filepath = b; bpy.ops.render.render(write_still=True)
    import subprocess
    subprocess.run(['convert', a, b, '-composite', os.path.join(OUT, name + '.png')], check=True)
    print('RENDER', name)
