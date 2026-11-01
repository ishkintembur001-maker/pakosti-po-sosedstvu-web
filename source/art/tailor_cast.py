"""Non-destructive tailored clothing geometry for the established two-storey cast.

Run after replace_faces.py and before polish_environments.py.
All new surfaces are parented to existing actor/limb transform pivots.
This intentionally leaves old meshes, face shape keys and animation actions intact.
"""
import bpy
import math
import os
from mathutils import Vector

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MASTER = os.path.join(ROOT, "art", "two_storey_faces.blend")
if not os.path.isfile(MASTER):
    raise RuntimeError("Missing anatomical cast master: " + MASTER)
bpy.ops.wm.open_mainfile(filepath=MASTER)

def material(name):
    item = bpy.data.materials.get(name)
    if item is None:
        raise RuntimeError("Missing original PBR material: " + name)
    return item

HOODIE = material("Petrol knit cotton")
DENIM = material("Indigo denim • twill")
ROBE = material("Burgundy plaid robe")
CAP = material("Woven red cap")
CREAM = material("Warm ivory enamel")
BRASS = material("Aged champagne brass")
ROOTS = ["TricksterCharacter", "NeighborCharacter"]
added = []

def mesh_part(name, coordinates, polygons, mat, parent):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(coordinates, [], polygons)
    mesh.update()
    if len(mesh.polygons) == 0:
        raise RuntimeError(name + " has no geometry")
    # The original character materials multiply Base Color by COLOR_0/Col.
    # Newly authored meshes MUST provide neutral white vertex colors;
    # otherwise glTF exports their fabric as black/near-black triangles.
    vertex_colors = mesh.color_attributes.new(
        name="Col", type="BYTE_COLOR", domain="POINT")
    for color in vertex_colors.data:
        color.color = (1.0, 1.0, 1.0, 1.0)
    if len(vertex_colors.data) != len(mesh.vertices):
        raise AssertionError("Missing neutral vertex colors: " + name)
    mesh.materials.append(mat)
    ob = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(ob)
    # Data coordinates are already expressed in the parent's local space.
    ob.parent = parent
    for polygon in mesh.polygons:
        polygon.use_smooth = True
    uv = mesh.uv_layers.new(name="ClothUV")
    for polygon in mesh.polygons:
        for loop_id in polygon.loop_indices:
            v = mesh.vertices[mesh.loops[loop_id].vertex_index].co
            uv.data[loop_id].uv = (v.x * 2.75 + v.y * .15, v.z * 3.1)
    ob["pakosti_clothing_detail"] = True
    added.append(ob)
    return ob

def ribbon(name, path, widths, mat, parent, lift=.013):
    if len(path) < 3 or len(widths) != len(path):
        raise ValueError("Need at least three fold sections and matching widths")
    # QA 2026-11-01: the narrow raised folds made black seams in real Godot
    # Compatibility screenshots even after fixing winding and COLOR_0.
    # Do not export those unstable floating patches to the mobile game.
    # Keep only broad neighbor shawl lapels, which define garment silhouette.
    if not name.startswith("Tailor_Neighbor_ShawlLapel_"):
        return None
    vertices = []
    faces = []
    for (x, y, z), w in zip(path, widths):
        # Broad, shallow fold with real facet curvature, not floating round trim.
        vertices.extend([
            (x-w, y+.004, z),
            (x-w*.38, y-lift*.58, z+.003),
            (x, y-lift, z),
            (x+w*.38, y-lift*.58, z+.003),
            (x+w, y+.004, z),
        ])
    for idx in range(len(path)-1):
        for col in range(4):
            i=idx*5+col
            # Rows run from shoulder to hem (descending Z). Reverse the quad
            # winding so the outward face points toward -Y, the actor's front.
            # The old winding pointed inward, yielding dark slit-like artifacts.
            faces.append((i+5,i+6,i+1,i))
    return mesh_part(name,vertices,faces,mat,parent)

def ring(name, center, rx, ry, z0, height, mat, parent, count=32, seam=0.0):
    verts = []
    for zz in (z0, z0+height):
        for i in range(count):
            angle=2*math.pi*i/count
            wave=1+.026*math.sin(5*angle+seam)
            verts.append((
                center[0]+rx*math.cos(angle)*wave,
                center[1]+ry*math.sin(angle)*wave,
                zz+.003*math.sin(3*angle+seam)
            ))
    faces = []
    for i in range(count):
        nxt=(i+1)%count
        faces.append((i,nxt,nxt+count,i+count))
    return mesh_part(name,verts,faces,mat,parent)

def local_pivot(root, kind, side):
    matches=[child for child in root.children
             if child.type=="EMPTY" and child.name.startswith(kind+"_"+side)]
    if len(matches)!=1:
        raise RuntimeError("%s: expected exactly one %s_%s hinge, got %d" %
                           (root.name, kind, side, len(matches)))
    return matches[0]

def detailed_hero(root):
    # Hoodie's chest and waist are elliptical lofts, front is negative Y.
    ring("Tailor_Hero_Hoodie_Waistband",(0,0),.305,.194,.628,.038,HOODIE,root,40,1.8)
    for idx,(side,points) in enumerate([
        (-1,[(-.26,-.141,1.10),(-.20,-.205,1.067),(-.10,-.246,1.034)]),
        (1,[(.26,-.141,1.10),(.20,-.205,1.067),(.10,-.246,1.034)]),
        (-1,[(-.24,-.153,.955),(-.17,-.215,.923),(-.07,-.255,.907)]),
        (1,[(.24,-.153,.955),(.17,-.215,.923),(.07,-.255,.907)]),
    ]):
        ribbon("Tailor_Hero_ChestDrape_%02d"%idx,points,[.007,.042,.003],HOODIE,root,.012)
    for idx, points in enumerate([
        [(-.245,-.165,.79),(-.13,-.251,.768),(.015,-.258,.748)],
        [(.245,-.165,.79),(.13,-.251,.766),(-.010,-.255,.741)],
        [(-.19,-.174,.690),(-.075,-.213,.672),(.095,-.213,.660)]
    ]):
        ribbon("Tailor_Hero_PocketWrinkle_%02d"%idx,points,[.003,.035,.002],HOODIE,root,.011)
    # Cuffs and sleeve compression are parented to the exact shoulder hinges.
    for s in ("L","R"):
        arm=local_pivot(root,"Arm",s)
        sign=-1 if s=="L" else 1
        ring("Tailor_Hero_Cuff_"+s,(sign*.108,-.128),.094,.096,-.431,.042,HOODIE,arm,32,1.2)
        for n in range(3):
            z=-.16-n*.072
            ribbon("Tailor_Hero_SleeveDart_%s_%d"%(s,n),
                   [(sign*.047,-.126,z+.031),(sign*.104,-.161,z),(sign*.165,-.126,z-.032)],
                   [.004,.018,.003],HOODIE,arm,.008)
        leg=local_pivot(root,"Legs",s)
        ring("Tailor_Hero_DenimCuff_"+s,(0,-.007),.098,.098,-.474,.045,DENIM,leg,32,.5)
        for n in range(2):
            ribbon("Tailor_Hero_KneeDrape_%s_%d"%(s,n),
                [(-.10,-.100,-.192-n*.067),(.0,-.125,-.206-n*.067),(.096,-.106,-.218-n*.067)],
                [.003,.014,.003],DENIM,leg,.008)

def detailed_neighbor(root):
    # Plaid robe: bent lapels, fabric belt compression and asymmetric drape.
    ring("Tailor_Neighbor_RobeHem",(0,.012),.472,.315,.602,.048,ROBE,root,44,1.1)
    for idx,sign in enumerate((-1,1)):
        ribbon("Tailor_Neighbor_ShawlLapel_%d"%idx,
           [(sign*.194,-.171,1.315),(sign*.265,-.298,1.184),
            (sign*.338,-.329,.998),(sign*.326,-.299,.840)],
           [.035,.093,.077,.026],ROBE,root,.045)
        ribbon("Tailor_Neighbor_WaistFold_%d"%idx,
            [(sign*.425,-.146,.785),(sign*.36,-.259,.732),
             (sign*.23,-.346,.700),(sign*.10,-.394,.681)],
            [.004,.043,.034,.003],ROBE,root,.015)
        ribbon("Tailor_Neighbor_ClothHang_%d"%idx,
            [(sign*.392,-.198,.665),(sign*.364,-.285,.564),
             (sign*.329,-.305,.470),(sign*.309,-.276,.402)],
            [.007,.039,.027,.003],ROBE,root,.025)
        arm=local_pivot(root,"Arm","L" if sign==-1 else "R")
        ring("Tailor_Neighbor_RobeSleeveCuff_%d"%idx,(sign*.102,-.068),.131,.134,-.315,.055,ROBE,arm,32,1.0)
        ribbon("Tailor_Neighbor_RobeSleeveFold_%d"%idx,
            [(sign*.036,-.169,-.113),(sign*.104,-.185,-.188),(sign*.160,-.148,-.261)],
            [.007,.035,.007],ROBE,arm,.021)
        leg=local_pivot(root,"Legs","L" if sign==-1 else "R")
        ring("Tailor_Neighbor_ShortsCuff_%d"%idx,(0,0),.188,.193,-.268,.040,ROBE,leg,32,0.2)
    # Subtle fasteners above the robe belt: constructed circles, not painted marks.
    for idx,z in enumerate((1.075,1.010,.947)):
        center=(.015,-.396,z)
        verts=[center]
        for i in range(12):
            a=i*2*math.pi/12
            verts.append((center[0]+.017*math.cos(a),center[1]-.003,center[2]+.017*math.sin(a)))
        faces=[(0,i+1,(i+1)%12+1) for i in range(12)]
        mesh_part("Tailor_Neighbor_Button_%d"%idx,verts,faces,BRASS,root)

original={
    name:{
        "animation_names":tuple(sorted(a.name for a in bpy.data.actions)),
        "faces":tuple(sorted((o.name,tuple(o.data.shape_keys.key_blocks.keys())) for o in bpy.data.objects
                              if o.type=="MESH" and o.data.shape_keys and o.name.startswith(("Hero_Face_","Neighbor_Face_"))))
    } for name in ROOTS
}
for name in ROOTS:
    actor=bpy.data.objects.get(name)
    if actor is None or actor.type!="EMPTY":
        raise RuntimeError("Character root missing: "+name)
    if any(c.name.startswith("Tailor_") for c in actor.children_recursive):
        raise RuntimeError("Tailor pass already applied; refusing duplicates")
    start=len(added)
    if name=="TricksterCharacter":
        detailed_hero(actor)
    else:
        detailed_neighbor(actor)
    created=len(added)-start
    # Hero retains waistband + limb cuffs, neighbor retains lapels, cuffs,
    # hem and discrete fasteners. Decorative shadow-slit folds are excluded.
    minimum=5 if name=="TricksterCharacter" else 10
    if created<minimum:
        raise AssertionError(name+": insufficient structural clothing geometry "+str(created))
    print("TAILORED_CAST_OK",name,created,flush=True)

if tuple(sorted(a.name for a in bpy.data.actions)) != original[ROOTS[0]]["animation_names"]:
    raise AssertionError("Art pass changed existing animation action inventory")
final_faces=tuple(sorted((o.name,tuple(o.data.shape_keys.key_blocks.keys())) for o in bpy.data.objects
                         if o.type=="MESH" and o.data.shape_keys and o.name.startswith(("Hero_Face_","Neighbor_Face_"))))
if final_faces != original[ROOTS[0]]["faces"] or len(final_faces)<2:
    raise AssertionError("Facial blendshapes altered or lost")
bpy.ops.wm.save_as_mainfile(filepath=MASTER)
print("TAILORED_SCENE_SAVED",len(added),len(final_faces),flush=True)
