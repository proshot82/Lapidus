# art/blender/misc.py — мелкие спрайты в стиле Blender-арта: фаянсовый горшок, пена протечки, капля, круглые кнопки HUD,
# эмалевая табличка с номером квартиры. Тот же мультяшный рендер (ступенчатая заливка, обводка Freestyle).
# Рисунок на фаянсе и значки на кнопках — слоем поверх (SVG из art/gen2.py, art/gen.py).
# Запуск: blender -b -P art/blender/misc.py -- <папка> [porcelain foam drop buttons plate]
import bpy, bmesh, math, sys, os, subprocess, json
from mathutils import Vector, Matrix
from bpy_extras.object_utils import world_to_camera_view

argv = sys.argv[sys.argv.index('--') + 1:]
OUT = argv[0]
ONLY = set(argv[1:])
os.makedirs(OUT, exist_ok=True)


def lin(c):
    c = c.lstrip('#'); v = [int(c[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return tuple(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in v)


def reset(res, scale, tilt=0.0, line=4.5):
    """res — (ширина, высота) px; scale — ширина кадра в единицах сцены; tilt — наклон камеры сверху (градусы)."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = 'BLENDER_EEVEE'
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.render.film_transparent = True
    sc.view_settings.view_transform = 'Standard'
    sc.render.use_freestyle = True
    sc.render.line_thickness_mode = 'ABSOLUTE'
    sc.render.line_thickness = 1.0
    vl = sc.view_layers[0]
    ls = vl.freestyle_settings.linesets.new('ol')
    ls.select_by_visibility = True
    ls.select_by_edge_types = True
    ls.select_silhouette = True
    ls.select_border = False
    ls.select_crease = False
    ls.select_external_contour = True
    ls.linestyle = bpy.data.linestyles.new('ol')
    ls.linestyle.color = (0.024, 0.016, 0.010)
    ls.linestyle.thickness = line
    for other in vl.freestyle_settings.linesets:
        if other.linestyle is None:
            other.linestyle = ls.linestyle
    t = math.radians(tilt)
    cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam'))
    cam.data.type = 'ORTHO'
    cam.data.ortho_scale = scale
    cam.location = (0, -10 * math.cos(t), 10 * math.sin(t))
    cam.rotation_euler = (math.radians(90) - t, 0, 0)
    sc.collection.objects.link(cam)
    sc.camera = cam
    sun = bpy.data.objects.new('sun', bpy.data.lights.new('sun', 'SUN'))
    sun.data.energy = 3.0
    sun.rotation_euler = (math.radians(50), math.radians(-35), math.radians(-25))
    sc.collection.objects.link(sun)
    sc.world = bpy.data.worlds.new('w')
    sc.world.use_nodes = True
    sc.world.node_tree.nodes['Background'].inputs[1].default_value = 0.0
    return sc


def toon(dark, mid, light, spec):
    m = bpy.data.materials.new('t'); m.use_nodes = True
    nt = m.node_tree; nt.nodes.clear()
    out = nt.nodes.new('ShaderNodeOutputMaterial')
    dif = nt.nodes.new('ShaderNodeBsdfDiffuse')
    s2r = nt.nodes.new('ShaderNodeShaderToRGB')
    ramp = nt.nodes.new('ShaderNodeValToRGB')
    emi = nt.nodes.new('ShaderNodeEmission')
    cr = ramp.color_ramp
    cr.interpolation = 'CONSTANT'
    cr.elements[0].position, cr.elements[0].color = 0.0, (*lin(dark), 1)
    cr.elements[1].position, cr.elements[1].color = 0.18, (*lin(mid), 1)
    e = cr.elements.new(0.55); e.color = (*lin(light), 1)
    e = cr.elements.new(0.92); e.color = (*lin(spec), 1)
    nt.links.new(dif.outputs[0], s2r.inputs[0])
    nt.links.new(s2r.outputs[0], ramp.inputs[0])
    nt.links.new(ramp.outputs[0], emi.inputs[0])
    nt.links.new(emi.outputs[0], out.inputs[0])
    return m


def flat(col):
    m = bpy.data.materials.new('f'); m.use_nodes = True
    nt = m.node_tree; nt.nodes.clear()
    out = nt.nodes.new('ShaderNodeOutputMaterial')
    emi = nt.nodes.new('ShaderNodeEmission'); emi.inputs[0].default_value = (*lin(col), 1)
    nt.links.new(emi.outputs[0], out.inputs[0])
    return m


def put(o, mat, smooth=True):
    if smooth:
        for p in o.data.polygons: p.use_smooth = True
    o.data.materials.append(mat)
    return o


def smooth_prof(pts, k=6):
    """Сгладить профиль (Катмулл — Ром): иначе ступенчатая заливка рисует грани."""
    out = []
    P = [pts[0]] + pts + [pts[-1]]
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[i - 1], P[i], P[i + 1], P[i + 2]
        for j in range(k):
            t = j / k
            out.append(tuple(.5 * (2 * p1[d] + (-p0[d] + p2[d]) * t + (2 * p0[d] - 5 * p1[d] + 4 * p2[d] - p3[d]) * t * t
                                   + (-p0[d] + 3 * p1[d] - 3 * p2[d] + p3[d]) * t ** 3) for d in (0, 1)))
    return out + [pts[-1]]


def lathe(profile, mat, segs=96):
    """Тело вращения вокруг оси Z по профилю [(r, z)]."""
    bm = bmesh.new()
    rings = [[bm.verts.new((r * math.cos(2 * math.pi * j / segs), r * math.sin(2 * math.pi * j / segs), z)) for j in range(segs)] for r, z in profile]
    for a, b in zip(rings, rings[1:]):
        for j in range(segs):
            bm.faces.new((a[j], a[(j + 1) % segs], b[(j + 1) % segs], b[j]))
    for ring, top in ((rings[0], False), (rings[-1], True)):
        if profile[0 if not top else -1][0] > 1e-4:
            f = bm.faces.new(ring if top else list(reversed(ring)))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new('l'); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new('l', me); bpy.context.scene.collection.objects.link(o)
    return put(o, mat)


def sphere(r, p, mat, scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=p, segments=48, ring_count=24)
    o = bpy.context.object; o.scale = scale
    bpy.ops.object.transform_apply(scale=True)
    return put(o, mat)


def anchor(sc, p):
    u = world_to_camera_view(sc, sc.camera, Vector(p))
    return u.x * sc.render.resolution_x, (1 - u.y) * sc.render.resolution_y


def render(sc, name):
    path = os.path.join(OUT, name + '_raw.png')
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)
    return path


def shadow(src, dst, blur=5, dx=5, dy=8, op=.45):
    subprocess.run(['convert', src, '(', '+clone', '-fill', 'black', '-colorize', '100', '-channel', 'A', '-evaluate', 'multiply', str(op),
                    '+channel', '-blur', '0x%s' % blur, '-roll', '+%d+%d' % (dx, dy), ')', '+swap', '-background', 'none', '-composite', dst], check=True)


AJ = os.path.join(OUT, 'misc_anchors.json')
AN = json.load(open(AJ)) if os.path.exists(AJ) else {}  # частичный прогон дополняет
if not ONLY or 'porcelain' in ONLY:          # эмалированный ночной горшок (фото Lao 03.10): широкая отогнутая кромка
    sc = reset((480, 480), 2.0, tilt=14)       # с тёмным кантом, крышка с петлёй, боковая ручка-«ухо»
    W = toon('#9FAAB6', '#DDE3EA', '#F4F7FA', '#FFFFFF')
    K = toon('#0E1216', '#1F262D', '#2E3740', '#46525E')
    body = [(0, -.34), (.20, -.34), (.27, -.32), (.31, -.27), (.33, -.18), (.335, -.05), (.33, .08), (.325, .14),
            (.34, .17), (.39, .19), (.44, .205), (.46, .215)]
    lathe(smooth_prof(body), W)
    bpy.ops.mesh.primitive_torus_add(major_radius=.46, minor_radius=.013, major_segments=96, minor_segments=8, location=(0, 0, .215))
    put(bpy.context.object, K)                                  # чёрный кант по кромке
    lathe(smooth_prof([(.43, .225), (.44, .235), (.40, .25), (.30, .275), (.16, .29), (0, .295)]), W)   # крышка
    bpy.ops.mesh.primitive_torus_add(major_radius=.065, minor_radius=.022, major_segments=48, minor_segments=12,
                                     location=(0, 0, .33), rotation=(math.radians(90), 0, 0))
    put(bpy.context.object, W)                                  # петля на крышке
    cu = bpy.data.curves.new('h', 'CURVE'); cu.dimensions = '3D'; cu.bevel_depth = .03; cu.bevel_resolution = 6
    sp = cu.splines.new('BEZIER'); pts = [(.31, 0, .10), (.46, 0, .10), (.49, 0, -.02), (.45, 0, -.14), (.32, 0, -.15)]
    sp.bezier_points.add(len(pts) - 1)
    for bp, p in zip(sp.bezier_points, pts):
        bp.co = p; bp.handle_left_type = bp.handle_right_type = 'AUTO'
    h = bpy.data.objects.new('h', cu); sc.collection.objects.link(h)
    bpy.context.view_layer.objects.active = h; h.select_set(True)
    bpy.ops.object.convert(target='MESH'); put(bpy.context.object, W)   # ручка-«ухо»
    AN['porcelain'] = {'chip': anchor(sc, (-.17, -.30, -.12)), 'top': anchor(sc, (0, 0, .36))}
    render(sc, 'porcelain')
if not ONLY or 'foam' in ONLY:               # пена протечки: клубы-сферы, снизу темнее, сверху светлее
    sc = reset((480, 480), 2.0)
    LO = toon('#0F4E78', '#1E8DCB', '#3FAEE5', '#9FE0FA')
    HI = toon('#1E8DCB', '#45BDF0', '#8ADAF8', '#E4F8FF')
    for x, z, r in ((-.20, -.07, .085), (-.07, -.10, .09), (.07, -.10, .09), (.20, -.07, .085)):
        sphere(r, (x, .05, z), LO)
    for x, z, r in ((-.15, .04, .095), (0, .07, .11), (.15, .04, .095), (-.06, -.02, .09), (.08, -.02, .09)):
        sphere(r, (x, 0, z), HI)
    for x, z, r in ((-.24, .12, .028), (.25, .10, .022), (.03, .21, .025), (-.10, .19, .016)):
        sphere(r, (x, -.05, z), HI)
    render(sc, 'foam')
if not ONLY or 'drop' in ONLY:               # капля
    sc = reset((120, 120), 2.0, line=3.0)
    D = toon('#0F6E9E', '#2EC4F1', '#7FDDF8', '#E4F8FF')
    # профиль капли: шар снизу (r .30 с центром на -.10), конус к острию на +.62
    prof = []
    for i in range(0, 13):
        a = -math.pi / 2 + i / 12 * (math.pi / 2 + .52)
        prof.append((.30 * math.cos(a), -.10 + .30 * math.sin(a)))
    x0, z0 = prof[-1]
    for i in range(1, 9):
        t = i / 8
        prof.append((x0 * (1 - t), z0 + (.62 - z0) * t))
    lathe(prof, D)
    render(sc, 'drop')
if not ONLY or 'buttons' in ONLY:            # кнопки HUD: латунный ободок, тёмное поле (значок — слоем поверх)
    sc = reset((144, 144), 144 / 60, line=4.0)
    B = toon('#7A5414', '#C9962E', '#EBC260', '#FFF3C2')
    K = toon('#151210', '#2A2622', '#3A342E', '#4A433B')
    bpy.ops.mesh.primitive_torus_add(major_radius=.88, minor_radius=.12, major_segments=96, minor_segments=24, rotation=(math.radians(90), 0, 0))
    put(bpy.context.object, B)
    bpy.ops.mesh.primitive_cylinder_add(vertices=96, radius=.80, depth=.10, rotation=(math.radians(90), 0, 0), location=(0, .02, 0))
    put(bpy.context.object, K, smooth=False)
    render(sc, 'button')
if not ONLY or 'plate' in ONLY:              # эмалевая табличка с номером квартиры (номер пишет движок)
    sc = reset((260, 180), 260 / 120, line=4.0)
    WH = toon('#A9A394', '#E3DED2', '#F2EEE4', '#FFFFFF')
    BL = toon('#122E5C', '#1F4E97', '#2E66B8', '#6E9AD8')
    SC = toon('#5E6770', '#A3ADB7', '#D3DAE1', '#FFFFFF')
    bpy.ops.mesh.primitive_cylinder_add(vertices=128, radius=1, depth=.08, rotation=(math.radians(90), 0, 0))
    o = bpy.context.object; o.scale = (.93, .63, 1); bpy.ops.object.transform_apply(scale=True)
    md = o.modifiers.new('b', 'BEVEL'); md.width = .03; md.segments = 4; bpy.ops.object.modifier_apply(modifier='b')
    put(o, WH)
    bpy.ops.mesh.primitive_cylinder_add(vertices=128, radius=1, depth=.04, rotation=(math.radians(90), 0, 0), location=(0, -.03, 0))
    o = bpy.context.object; o.scale = (.81, .51, 1); bpy.ops.object.transform_apply(scale=True)
    put(o, BL, smooth=False)
    for x in (-.83, .83):
        sphere(.06, (x, -.05, 0), SC, (1, .5, 1))
    AN['plate'] = {'ring': [anchor(sc, (0, -.06, 0)), anchor(sc, (.75, -.06, .45))]}
    render(sc, 'plate')

# ---------- сеть для карточек правил: стояк с вентилем, глухой отвод на кронштейне, решётка слива (как в фоне квартир)
R_BODY, R_SOCK, R_THR, LIM = .18, .23, .15, .47
DV = {'right': (1, 0), 'left': (-1, 0), 'up': (0, 1), 'down': (0, -1)}


def cylp(r, a, b, mat, verts=40):
    a, b = Vector(a), Vector(b)
    d = b - a
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=d.length)
    o = bpy.context.object
    o.rotation_mode = 'QUATERNION'
    o.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(d.normalized())
    o.location = (a + b) / 2
    bpy.ops.object.transform_apply(location=True, rotation=True)
    return put(o, mat)


def P(d, t):
    return (DV[d][0] * t, 0, DV[d][1] * t)


def net_port(d, th, mat):
    cylp(R_BODY * .97, P(d, .12), P(d, .30), mat)
    if th == 'N':   # резьба одним проходом: витки — кольца, обводка Freestyle только по силуэту
        cylp(R_THR, P(d, .26), P(d, LIM), mat)
        t = .28
        while t < LIM - .01:
            bpy.ops.mesh.primitive_torus_add(major_radius=R_THR * .95, minor_radius=R_THR * .12, major_segments=40, minor_segments=6)
            o = bpy.context.object
            o.rotation_mode = 'QUATERNION'
            o.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(Vector((DV[d][0], 0, DV[d][1])))
            o.location = P(d, t)
            bpy.ops.object.transform_apply(location=True, rotation=True)
            put(o, mat)
            t += .05
    else:
        cylp(R_SOCK, P(d, .26), P(d, LIM), mat)


def net_mats():
    return (toon('#3E454C', '#7C868F', '#B3BCC5', '#EEF2F6'), toon('#2C3136', '#4F5760', '#7E8892', '#C9D0D7'),
            toon('#7E2116', '#C83E2C', '#E2604B', '#F59A83'), toon('#7A5414', '#C9962E', '#EBC260', '#FFF3C2'))


if not ONLY or 'net' in ONLY:
    # стояк: выход вправо (В), вентиль, фланцы, заглушки на концах — холст 2 клетки, стояк по всей высоте
    for d, th in (('right', 'V'),):
        sc = reset((480, 480), 2.0)
        ST, IR, RD, BR = net_mats()
        cylp(.22, (0, 0, -.90), (0, 0, .90), IR, 48)
        for zz in (-.90, .90):
            cylp(.27, (0, 0, zz - .06), (0, 0, zz + .06), IR, 48)
        for zz in (-.50, .50):
            cylp(.31, (0, 0, zz - .06), (0, 0, zz + .06), IR, 48)
            for bx in (-.22, .22):
                sphere(.035, (bx, -.29, zz), ST, (1, .6, 1))
        sphere(.27, (0, 0, 0), IR, (1, 1, 1.15))
        net_port(d, th, ST)
        cylp(.04, (0, -.2, 0), (0, -.5, 0), ST, 16)
        bpy.ops.mesh.primitive_torus_add(major_radius=.20, minor_radius=.034, major_segments=64, minor_segments=12,
                                         location=(0, -.52, 0), rotation=(math.radians(90), 0, 0))
        put(bpy.context.object, RD)
        for k in range(4):
            a = math.pi / 4 + k * math.pi / 2
            cylp(.024, (0, -.52, 0), (math.cos(a) * .19, -.52, math.sin(a) * .19), RD, 16)
        sphere(.055, (0, -.54, 0), BR)
        render(sc, 'src_%s%s' % (d[0], th))
    # глухой отвод на кронштейне: выход d, крепление к стене m
    for d, th, m in (('down', 'V', 'up'), ('right', 'V', 'left')):
        sc = reset((480, 480), 2.0)
        ST, IR, RD, BR = net_mats()
        cylp(R_BODY * .97, (0, 0, 0), P(m, .40), ST)
        bpy.ops.mesh.primitive_cube_add(size=1, location=P(m, .44))
        o = bpy.context.object
        o.scale = (.10, .5, .62) if DV[m][0] else (.62, .5, .10)
        bpy.ops.object.transform_apply(scale=True)
        md = o.modifiers.new('b', 'BEVEL'); md.width = .025; md.segments = 3
        bpy.ops.object.modifier_apply(modifier='b')
        put(o, IR)
        net_port(d, th, ST)
        cylp(R_BODY * .97, (0, 0, 0), P(d, .14), ST)
        render(sc, 'stub_%s%s_%s' % (d[0], th, m[0]))
    # решётка слива в перспективе (тёмная шахта и вода — слоем в карточке)
    sc = reset((480, 480), 2.0)
    GR = toon('#22272C', '#3C434A', '#5C646C', '#8A939B')
    before = set(sc.objects)
    bpy.ops.mesh.primitive_torus_add(major_radius=.44, minor_radius=.035, major_segments=64, minor_segments=10)
    put(bpy.context.object, GR)
    for k in (-.30, -.15, 0, .15, .30):
        h = math.sqrt(.44 ** 2 - k ** 2)
        cylp(.022, (k, -h, 0), (k, h, 0), GR, 12)
    for o in [o for o in sc.objects if o not in before]:
        o.data.transform(Matrix.Rotation(math.radians(10), 4, 'X'))
        o.data.update()
    render(sc, 'grate')
with open(AJ, 'w') as f:
    json.dump(AN, f)
print('MISC done')
