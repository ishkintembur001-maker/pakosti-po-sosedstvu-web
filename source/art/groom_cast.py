"""Shape-language hair grooming for a mobile Godot cast, not a stock hat of tubes.

Inputs: Blender faces master after sculpt_cast.py. Output: same editable master.
Anatomical face morph targets, eyelids, skin material, all nine body actions,
character scale, cap and all collision/gameplay data remain unchanged.
"""
import bpy
import bmesh
import math
import os
from mathutils import Vector

ROOT=os.path.abspath(os.path.join(os.path.dirname(__file__),".."))
MASTER=os.path.join(ROOT,"art","two_storey_faces.blend")
if not os.path.isfile(MASTER):
    raise RuntimeError("Anatomical cast master missing: "+MASTER)
bpy.ops.wm.open_mainfile(filepath=MASTER)

actor_data=(
    ("TricksterCharacter","GroomedHair_Hero",False),
    ("NeighborCharacter","GroomedHair_Neighbor",True)
)
original_actions=tuple(sorted(a.name for a in bpy.data.actions))
original_faces={
  name:tuple(sorted((o.name,tuple(k.name for k in o.data.shape_keys.key_blocks))
                    for o in bpy.data.objects if o.type=="MESH"
                    and o.parent==bpy.data.objects.get(name)
                    and o.data.shape_keys))
  for name,_,_ in actor_data
}

def hair_material(name,color,roughness):
    material=bpy.data.materials.get(name)
    if material is None:
        material=bpy.data.materials.new(name)
        material.use_nodes=True
        p=material.node_tree.nodes.get("Principled BSDF")
        p.inputs["Base Color"].default_value=(*color,1)
        p.inputs["Roughness"].default_value=roughness
        p.inputs["Metallic"].default_value=0
        material.diffuse_color=(*color,1)
    return material

materials=[
  hair_material("Hair sculpt - chestnut umber",(.155,.088,.057),.79),
  hair_material("Hair sculpt - warm chestnut",(.244,.136,.089),.81),
  hair_material("Hair sculpt - lit copper",(.345,.201,.125),.78)
]

# Each irregular lock is genuine 3D volume with a soft cross section;
# no alpha cards, transparent sorting or hair particles on mobile GPUs.
class HairMesh:
    def __init__(self,actor,meshname):
        self.actor=actor
        self.meshname=meshname
        self.vertices=[]
        self.faces=[]
        self.material_ids=[]
        self.uvcoords=[]
        self.locks=0
    def lock(self,points,radii,tone,seed):
        if len(points)!=len(radii) or len(points)<4:
            raise RuntimeError("Malformed tapered strand")
        steps=10
        start=len(self.vertices)
        pts=[Vector(p) for p in points]
        for i,(point,radius) in enumerate(zip(pts,radii)):
            tangent=(pts[min(i+1,len(pts)-1)]-pts[max(0,i-1)]).normalized()
            u=tangent.cross(Vector((0,0,1)))
            if u.length<.02:
                u=tangent.cross(Vector((0,1,0)))
            u.normalize()
            v=tangent.cross(u).normalized()
            for j in range(steps):
                theta=math.tau*j/steps
                # Flattened-to-ribbon silhouette makes a faceted sculpt,
                # not uniform cylinders. A subtle twist follows the lock.
                width=radius*(1+.11*math.cos(3*theta+seed))
                p=point+u*(width*math.cos(theta))+v*(width*.64*math.sin(theta))
                self.vertices.append(tuple(p))
                self.uvcoords.append((j/steps,i/(len(pts)-1)))
        for i in range(len(pts)-1):
            for j in range(steps):
                a=start+i*steps+j
                b=start+i*steps+(j+1)%steps
                c=b+steps
                d=a+steps
                self.faces.append((a,b,c,d))
                self.material_ids.append(tone)
        self.faces.append(tuple(start+j for j in reversed(range(steps))))
        self.material_ids.append(tone)
        self.locks+=1
    def finish(self):
        if self.locks<12:
            raise RuntimeError("Insufficient sculpted hair locks")
        mesh=bpy.data.meshes.new(self.meshname)
        mesh.from_pydata(self.vertices,[],self.faces)
        mesh.update()
        for material in materials:
            mesh.materials.append(material)
        for p,tone in zip(mesh.polygons,self.material_ids):
            p.material_index=tone
            p.use_smooth=True
        layer=mesh.uv_layers.new(name="GroomUV")
        for p in mesh.polygons:
            for li in p.loop_indices:
                v=mesh.loops[li].vertex_index
                layer.data[li].uv=self.uvcoords[v]
        # Original game shaders sometimes use COLOR_0; white is neutral.
        col=mesh.color_attributes.new(name="Col",type="BYTE_COLOR",domain="POINT")
        for point in col.data:
            point.color=(1,1,1,1)
        obj=bpy.data.objects.new(self.meshname,mesh)
        bpy.context.collection.objects.link(obj)
        obj.parent=self.actor
        obj["pakosti_reference_groom"]="structured layered head hair with swept tuft silhouette"
        obj["pakosti_groom_locks"]=self.locks
        if len(mesh.polygons)>2500:
            raise RuntimeError("Groom exceeds mobile polygon budget")
        print("GROOM_CAST_OK",obj.name,"locks",self.locks,"polygons",len(mesh.polygons),flush=True)

def hero_groom(part):
    # Red reversed cap is retained, while thick older 'sausages' are replaced.
    # Under-cap volume is arranged as staggered overlapping sculpted clumps.
    for row,count in enumerate((19,15)):
        for k in range(count):
            ratio=k/(count-1)
            x0=-.296+ratio*.592+(row*.006)
            wav=math.sin(k*2.17+row*.73)
            drift=.037+.024*math.sin(k*1.11+row)
            root_z=1.913-.028*abs(x0)+row*.017
            tip_z=1.768+.036*math.sin((ratio+.1)*math.pi)+.012*wav
            root_y=-.105+row*.018
            tip_y=-.282+row*.015-.012*math.cos(k*1.6)
            points=[]
            for j in range(7):
                t=j/6
                smooth=t*t*(3-2*t)
                x=x0+drift*smooth
                y=root_y+(tip_y-root_y)*smooth-.019*math.sin(math.pi*t)
                z=root_z+(tip_z-root_z)*smooth+.015*math.sin(math.pi*t)
                points.append((x,y,z))
            radii=[.046,.053,.053,.045,.033,.018,.0025] if row==0 else [.037,.044,.046,.037,.025,.013,.0025]
            part.lock(points,radii,(k+row*2)%3,k*.43+row)
    # Longer swept tufts at both temples, below the backward cap, above ears.
    for side in (-1,1):
        for k in range(8):
            x=side*(.298+.014*k)
            z0=1.877+.012*math.cos(k)
            z1=1.644+.023*k
            y0=.006+.01*k
            points=[]
            for j in range(7):
                t=j/6
                points.append((
                    x+side*(.055*math.sin(math.pi*t)),
                    y0-.15*t-.02*math.sin(math.pi*t),
                    z0+(z1-z0)*t
                ))
            part.lock(points,[.040,.052,.052,.046,.029,.015,.002],(k+1)%3,k*1.2+side)

def neighbor_groom(part):
    # Maintain the receding hairline and side tufts of the angry neighbor.
    # New layered swept sides soften the previously jagged mohawk silhouette.
    for side in (-1,1):
        for k in range(11):
            ratio=k/10
            x=side*(.315+.035*ratio)
            z0=2.013+.019*math.cos(k*.63)
            z1=1.693+.072*ratio
            y0=.120-.025*ratio
            tip_y=-.157-.027*ratio
            points=[]
            for j in range(7):
                t=j/6
                points.append((
                    x+side*(.055*math.sin(math.pi*t)+.015*t),
                    y0+(tip_y-y0)*t-.023*math.sin(math.pi*t),
                    z0+(z1-z0)*(t*t*(3-2*t))
                ))
            part.lock(points,[.056,.068,.070,.059,.044,.023,.002],(k+1)%3,k*.67+side)

for name,meshname,is_enemy in actor_data:
    actor=bpy.data.objects.get(name)
    if actor is None or actor.type!="EMPTY":
        raise RuntimeError("Original animated cast missing: "+name)
    if bpy.data.objects.get(meshname):
        raise RuntimeError("Groom already exists, refusing duplicate: "+meshname)
    if not is_enemy:
        old=[o for o in actor.children if o.type=="MESH" and o.name.startswith("Swept forelock")]
        if len(old)<5:
            raise RuntimeError("Expected original crude fringe for safe replacement")
        for obj in old:
            bpy.data.objects.remove(obj,do_unlink=True)
    groom=HairMesh(actor,meshname)
    if is_enemy:
        neighbor_groom(groom)
    else:
        hero_groom(groom)
    groom.finish()

if tuple(sorted(a.name for a in bpy.data.actions))!=original_actions:
    raise AssertionError("Character animation actions were altered")
for name,_,_ in actor_data:
    now=tuple(sorted((o.name,tuple(k.name for k in o.data.shape_keys.key_blocks))
                     for o in bpy.data.objects if o.type=="MESH"
                     and o.parent==bpy.data.objects.get(name)
                     and o.data.shape_keys))
    if now!=original_faces[name]:
        raise AssertionError("Facial blendshapes changed for "+name)
bpy.ops.wm.save_as_mainfile(filepath=MASTER)
print("REFERENCE_GROOM_SAVE_OK",flush=True)
