"""Conservative facial/cloth sculpt and finger detail for existing game characters.
Runs after tailor_cast.py, before polish_environments.py in Blender 4.3.2.
Reuses all existing animations, facial morphs, UVs and game layout.
"""
import bpy
import bmesh
import math
import os
from mathutils import Vector
ROOT=os.path.abspath(os.path.join(os.path.dirname(__file__),".."))
MASTER=os.path.join(ROOT,"art","two_storey_faces.blend")
bpy.ops.wm.open_mainfile(filepath=MASTER)
actors=(("TricksterCharacter","Hero_Face_Anatomy",False),("NeighborCharacter","Neighbor_Face_Anatomy",True))
actions=tuple(sorted(a.name for a in bpy.data.actions))
def gauss(x,c,r):return math.exp(-((x-c)/r)**2)
def face_sculpt(ob,enemy):
    blocks=ob.data.shape_keys.key_blocks if ob.data.shape_keys else None
    if not blocks or any(n not in blocks for n in ("Basis","Smile","Frown","Blink")):
        raise RuntimeError("Missing cast face morphs "+ob.name)
    basis=blocks["Basis"]
    diffs=[(Vector(blocks["Smile"].data[i].co)-Vector(basis.data[i].co),
            Vector(blocks["Blink"].data[i].co)-Vector(basis.data[i].co))
           for i in range(len(ob.data.vertices))]
    hits=0
    for i,vert in enumerate(basis.data):
        x,y,z=vert.co
        falloff=gauss(y,-.268 if enemy else -.246,.155)
        cheek=max(gauss(x,.258 if enemy else .222,.117),
                  gauss(x,-.258 if enemy else -.222,.117))
        depth=(.023 if enemy else .018)*cheek*gauss(z,1.61 if enemy else 1.52,.125)*falloff
        jaw=.006*gauss(abs(x),.19,.17)*gauss(z,1.45 if enemy else 1.36,.11)*falloff
        delta=Vector((0,-(depth+jaw)*(1.0 if enemy else (1.05 if x>0 else .95)),0))
        if delta.length<.000001:continue
        for block in blocks:block.data[i].co=Vector(block.data[i].co)+delta
        hits+=1
    for i,(smile,blink) in enumerate(diffs):
        b=Vector(basis.data[i].co)
        if (Vector(blocks["Smile"].data[i].co)-b-smile).length>.00002:
            raise AssertionError("Smile morph altered")
        if (Vector(blocks["Blink"].data[i].co)-b-blink).length>.00002:
            raise AssertionError("Blink morph altered")
    if hits<80:raise RuntimeError("Face sculpt region too small "+ob.name)
    ob.data.update()
    print("SCULPT_FACE_OK",ob.name,hits,flush=True)
def deform_outfit(actor,enemy):
    material="Burgundy plaid robe" if enemy else "Petrol knit cotton"
    targets=[o for o in actor.children if o.type=="MESH" and any(m and m.name.startswith(material) for m in o.data.materials)]
    if not targets:raise RuntimeError("Original body outfit absent "+actor.name)
    edits=0
    for o in targets:
        if o.data.shape_keys:raise RuntimeError("Refusing topology change on morph mesh")
        bm=bmesh.new();bm.from_mesh(o.data)
        if len(bm.verts)>12000:raise RuntimeError("Mesh out of mobile polygon budget")
        bmesh.ops.subdivide_edges(bm,edges=list(bm.edges),cuts=1,use_grid_fill=True)
        for v in bm.verts:
            x,y,z=v.co
            if y>=-.06:continue
            if enemy:
                env=gauss(abs(x),.38,.19)*gauss(z,.90,.32)*gauss(y,-.20,.22)
                move=.009*env*math.sin(23*z+6*abs(x))
            else:
                env=gauss(x,0,.285)*gauss(z,.945,.23)*gauss(y,-.20,.145)
                move=env*(.007*math.sin(24*z+9*x)+.005*math.sin(31*z-11*x))
            if abs(move)>.00001:v.co.y-=move;edits+=1
        bm.to_mesh(o.data);bm.free();o.data.update()
    if edits<30:raise RuntimeError("Not enough vertices for cloth sculpt "+actor.name)
    print("SCULPT_OUTFIT_OK",actor.name,edits,flush=True)
def make_nails(actor,enemy):
    mat=bpy.data.materials.get("Natural nail keratin")
    if mat is None:
        mat=bpy.data.materials.new("Natural nail keratin")
        mat.use_nodes=True
        p=mat.node_tree.nodes.get("Principled BSDF")
        p.inputs["Base Color"].default_value=(.68,.48,.38,1)
        p.inputs["Roughness"].default_value=.47
    for side,sign in (("L",-1),("R",1)):
        pivots=[o for o in actor.children if o.type=="EMPTY" and o.name.startswith("Arm_"+side)]
        if len(pivots)!=1:raise RuntimeError("Expected one "+actor.name+" shoulder "+side)
        verts=[];faces=[]
        for finger in range(4):
            x0=sign*.10-.069+finger*.044
            z0=-.583
            base=len(verts)
            for scale,y in ((1,-.212),(.72,-.217)):
                for j in range(12):
                    a=math.tau*j/12
                    verts.append((x0+.016*scale*math.cos(a),y,z0+.021*scale*math.sin(a)))
            verts.append((x0,-.218,z0))
            for j in range(12):
                k=(j+1)%12
                faces.append((base+j,base+k,base+12+k,base+12+j))
                faces.append((base+12+j,base+12+k,base+24))
        mesh=bpy.data.meshes.new(actor.name+"_Nails_"+side)
        mesh.from_pydata(verts,[],faces);mesh.update()
        uv=mesh.uv_layers.new(name="NailUV")
        for polygon in mesh.polygons:
            polygon.use_smooth=True
            for li in polygon.loop_indices:
                c=mesh.vertices[mesh.loops[li].vertex_index].co
                uv.data[li].uv=((c.x+.4)*2,(c.z+.8)*2)
        col=mesh.color_attributes.new(name="Col",type="BYTE_COLOR",domain="POINT")
        for datum in col.data:datum.color=(1,1,1,1)
        mesh.materials.append(mat)
        ob=bpy.data.objects.new(actor.name+"_HandNails_"+side,mesh)
        bpy.context.collection.objects.link(ob)
        ob.parent=pivots[0]
        print("SCULPT_FINGERS_OK",ob.name,len(mesh.polygons),flush=True)
for actorname,facename,enemy in actors:
    actor=bpy.data.objects.get(actorname)
    head=bpy.data.objects.get(facename)
    if not actor or not head or head.parent!=actor:raise RuntimeError("Source actor head missing "+actorname)
    if any(o.name.startswith(actorname+"_HandNails_") for o in bpy.data.objects):
        raise RuntimeError("Sculpt pass already applied")
    face_sculpt(head,enemy)
    deform_outfit(actor,enemy)
    make_nails(actor,enemy)
if tuple(sorted(a.name for a in bpy.data.actions))!=actions:
    raise RuntimeError("Game animation actions changed")
bpy.ops.wm.save_as_mainfile(filepath=MASTER)
print("SCULPT_CAST_SAVED",MASTER,flush=True)
