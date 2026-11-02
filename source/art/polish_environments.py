"""Reproducible mobile environment pass: PBR maps, UV2 AO atlas and floor heights.
Bakes actual static geometry in Cycles on CPU. Characters and gameplay layout stay intact.
Run after build_assets.py, refine_cast.py and replace_faces.py with Blender 4.3.2.
"""
import bpy,bmesh,math,os,json,struct,time
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
H=3.35
PALETTE={
 'Honey oak • grain':('9d7653',.58,.30),
 'Walnut • polished edges':('513c2c',.50,.28),
 'Sage damask • woven wallpaper':('728571',.95,.14),
 'Upstairs powder blue wallpaper':('829b9b',.94,.14),
 'Dusty rose bedroom wallpaper':('92766b',.94,.14),
 'Oxblood upholstery • woven checks':('87504a',.96,.45),
 'Muted jade glazed tile':('6b8980',.34,.20),
 'Persian wool • ornamental border':('833d3e',.98,.52),
}
def lin(v):return v/12.92 if v<.04045 else ((v+.055)/1.055)**2.4
def rgb(h):return tuple(lin(int(h[i:i+2],16)/255) for i in (0,2,4))
def image(name,array,space):
 h,w=array.shape[:2];im=bpy.data.images.new(name,width=w,height=h);im.colorspace_settings.name=space;im.pixels.foreach_set(array.astype(np.float32).ravel());im.pack();return im

def material_copy(source,atlas,uvname,tag):
 m=source.copy();m.name=tag+' / '+source.name;p=m.node_tree.nodes.get('Principled BSDF')
 if not p:return m,None
 tint=None
 if source.name in PALETTE:
  hex_color,roughness,contrast=PALETTE[source.name];tint=rgb(hex_color)
  tex=next((n for n in m.node_tree.nodes if n.type=='TEX_IMAGE' and n.image and not n.image.name.lower().endswith('normal')),None)
  wood=source.name in ('Honey oak • grain','Walnut • polished edges')
  if wood:
   if tex is None:tex=m.node_tree.nodes.new('ShaderNodeTexImage')
   tex.image=bpy.data.images.load(os.path.join(ROOT,'art/source/materials/fine_wood_color.jpg'),check_existing=True)
  if tex and tex.image and tex.image.size[0]>0 and tex.image.size[1]>0:
   original=np.array(tex.image.pixels[:],np.float32).reshape(tex.image.size[1],tex.image.size[0],4)
   value=original[:,:,:3].mean(axis=2);average=max(float(value.mean()),.0001)
   mod=np.clip(.95+contrast*(value/average-1),.60,1.0)
   pixels=np.ones_like(original);pixels[:,:,:3]=mod[:,:,None]
   tex.image=image(m.name+' tonal weave',pixels,'sRGB')
   for link in list(p.inputs['Base Color'].links):m.node_tree.links.remove(link)
   multiply=m.node_tree.nodes.new('ShaderNodeMixRGB');multiply.blend_type='MULTIPLY';multiply.inputs[0].default_value=1;multiply.inputs[2].default_value=(*tint,1);m.node_tree.links.new(tex.outputs['Color'],multiply.inputs[1]);m.node_tree.links.new(multiply.outputs['Color'],p.inputs['Base Color'])
   # UV-space relief is deliberately subtle, not the previous large wood bands.
   gy,gx=np.gradient(mod);normal=np.stack([-gx*3,-gy*3,np.ones_like(mod)],axis=2);normal/=np.linalg.norm(normal,axis=2,keepdims=True)
   normal_pixels=np.ones_like(original);normal_pixels[:,:,:3]=normal*.5+.5
   nt=m.node_tree.nodes.new('ShaderNodeTexImage');nt.image=image(m.name+' micro normal',normal_pixels,'Non-Color')
   if wood:
    nt.image=bpy.data.images.load(os.path.join(ROOT,'art/source/materials/fine_wood_normal.jpg'),check_existing=True);nt.image.colorspace_settings.name='Non-Color';nt.image.pack()
   nm=m.node_tree.nodes.new('ShaderNodeNormalMap');nm.inputs['Strength'].default_value=.32;m.node_tree.links.new(nt.outputs['Color'],nm.inputs['Color']);m.node_tree.links.new(nm.outputs['Normal'],p.inputs['Normal'])
   rp=np.ones_like(original);rp[:,:,:3]=np.clip(roughness+(1-mod[:,:,None])*.10,0,1)
   rt=m.node_tree.nodes.new('ShaderNodeTexImage');rt.image=image(m.name+' roughness',rp,'Non-Color')
   if wood:
    scan=bpy.data.images.load(os.path.join(ROOT,'art/source/materials/fine_wood_roughness.jpg'),check_existing=True);scan.colorspace_settings.name='Non-Color'
    values=np.array(scan.pixels[:],np.float32).reshape(scan.size[1],scan.size[0],4);values[:,:,:3]=np.clip(roughness+(values[:,:,:3]-.5)*.18,.3,.85);rt.image=image(m.name+' scanned roughness',values,'Non-Color')
   m.node_tree.links.new(rt.outputs['Color'],p.inputs['Roughness']);p.inputs['Roughness'].default_value=1
  else:
   for link in list(p.inputs['Base Color'].links):m.node_tree.links.remove(link)
   p.inputs['Base Color'].default_value=(*tint,1);p.inputs['Roughness'].default_value=roughness
 # The exporter recognizes this official node-group interface and writes occlusionTexture.texCoord=1.
 group=bpy.data.node_groups.get('glTF Material Output')
 if group is None:
  group=bpy.data.node_groups.new('glTF Material Output','ShaderNodeTree');group.interface.new_socket(name='Occlusion',in_out='INPUT',socket_type='NodeSocketFloat');group.nodes.new('NodeGroupInput');group.nodes.new('NodeGroupOutput')
 settings=m.node_tree.nodes.new('ShaderNodeGroup');settings.node_tree=group
 ao=m.node_tree.nodes.new('ShaderNodeTexImage');ao.image=atlas;ao.extension='EXTEND'
 uv=m.node_tree.nodes.new('ShaderNodeUVMap');uv.uv_map=uvname;m.node_tree.links.new(uv.outputs['UV'],ao.inputs['Vector']);m.node_tree.links.new(ao.outputs['Color'],settings.inputs['Occlusion'])
 return m,tint

def refine_floor_joints(objects):
 count=0
 for obj in objects:
  if '00_Architecture' not in obj.name:continue
  bm=bmesh.new();bm.from_mesh(obj.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00001)
  remaining=set(bm.verts)
  while remaining:
   first=remaining.pop();group={first};pending=[first]
   while pending:
    v=pending.pop()
    for edge in v.link_edges:
     other=edge.other_vert(v)
     if other in remaining:remaining.remove(other);group.add(other);pending.append(other)
   coords=[obj.matrix_world@v.co for v in group];lo=Vector(tuple(min(v[i] for v in coords) for i in range(3)));hi=Vector(tuple(max(v[i] for v in coords) for i in range(3)));size=hi-lo;center=(lo+hi)*.5
   floor=round((center.z-.197)/H)
   if floor not in (0,1) or abs(center.z-(floor*H+.197))>.015 or size.z>.025:continue
   axis=0 if size.x<size.y else 1
   if size[axis]>.015 or max(size.x,size.y)<.15:continue
   # Subpixel raised lines flicker into black dots at the mobile render scale.
   # Remove only these disconnected decorative joints; deck and stairs remain intact.
   bmesh.ops.delete(bm,geom=list(group),context='VERTS');count+=1
  bm.to_mesh(obj.data);bm.free();obj.data.update()
 print('FLOOR_JOINTS_REMOVED',count,flush=True)

def floor_grid(objects,path):
 vertices=[];faces=[]
 for obj in objects:
  matrix=obj.matrix_world
  for poly in obj.data.polygons:
   coords=[matrix@obj.data.vertices[i].co for i in poly.vertices]
   z=sum(v.z for v in coords)/len(coords)
   if not any(f*H+.12<z<f*H+.52 for f in [0,1]):continue
   normal=(coords[1]-coords[0]).cross(coords[2]-coords[0])
   if normal.length<1e-8 or normal.normalized().z<.65:continue
   base=len(vertices);vertices.extend(coords);faces.append(tuple(range(base,base+len(coords))))
 tree=BVHTree.FromPolygons(vertices,faces);w,d=153,57;step=.1;origin=(-7.6,-2.8);floors=[]
 for f in range(2):
  values=[]
  for j in range(d):
   for i in range(w):
    x=origin[0]+i*step;z=origin[1]+j*step
    hit=tree.ray_cast(Vector((x,-z,f*H+.525)),Vector((0,0,-1)),.5)[0]
    values.append(round(hit.z if hit else f*H+.19,4))
  floors.append(values)
 os.makedirs(os.path.dirname(path),exist_ok=True)
 with open(path,'w') as file:json.dump({'origin':origin,'cell':step,'width':w,'depth':d,'floors':floors},file,separators=(',',':'))
 print('FLOOR_GRID_OK',w,d,min(floors[0]),max(floors[0]),flush=True)

def export(scene_name,output):
 for o in bpy.data.objects:
  if o.animation_data:
   for track in o.animation_data.nla_tracks:track.mute=False
   if o.animation_data.nla_tracks:o.animation_data.action=o.animation_data.nla_tracks[0].strips[0].action
 bpy.ops.export_scene.gltf(filepath=output,export_format='GLB',export_animations=True,export_animation_mode='NLA_TRACKS',export_nla_strips=True,export_force_sampling=True,export_frame_range=False,export_cameras=False,export_lights=False,export_morph=True)
 # Keep one tint per material; textures are near-white detail modulations.
 b=open(output,'rb').read();n=struct.unpack_from('<I',b,12)[0];doc=json.loads(b[20:20+n]);tail=b[20+n:]
 for m in doc['materials']:
  if m.get('name')=='Anatomical skin complexion':m['pbrMetallicRoughness']['baseColorFactor']=[*rgb('d7ab92'),1]
  source=m.get('name','').split(' / ',1)[-1]
  if m.get('name','').startswith(scene_name+' / ') and source in PALETTE:
   pbr=m['pbrMetallicRoughness'];pbr['baseColorFactor']=[*rgb(PALETTE[source][0]),1]
   if pbr.get('metallicRoughnessTexture'):pbr['roughnessFactor']=1
 data=json.dumps(doc,separators=(',',':')).encode();data+=b' '*((-len(data))%4)
 open(output,'wb').write(struct.pack('<III',0x46546c67,2,20+len(data)+len(tail))+struct.pack('<II',len(data),0x4e4f534a)+data+tail)
 print('ENVIRONMENT_EXPORT_OK',output,'AO materials=',sum('occlusionTexture' in m for m in doc['materials']),flush=True)

def polish(source,root_name,tag,size,output,write_floor=False):
 started=time.time();bpy.ops.wm.open_mainfile(filepath=source);scene=bpy.context.scene
 for source_image in bpy.data.images:
  if source_image.source=='FILE':
   filename=os.path.basename(source_image.filepath)
   candidate=os.path.join(ROOT,'art/textures',filename)
   if os.path.exists(candidate):source_image.filepath=candidate;source_image.reload()
 root=bpy.data.objects[root_name];objects=[o for o in root.children_recursive if o.type=='MESH']
 if write_floor:refine_floor_joints(objects)
 if write_floor:floor_grid(objects,os.path.join(ROOT,'assets/data/floor_surfaces.json'))
 # Exclude the actors and every non-static mesh from the ambient bake.
 hidden={o:o.hide_render for o in scene.objects if o.type=='MESH'}
 selected=set(objects)
 for obj in hidden:obj.hide_render=obj not in selected
 saved={o:(list(o.data.materials),[p.material_index for p in o.data.polygons]) for o in objects}
 bpy.ops.object.select_all(action='DESELECT')
 for obj in objects:
  obj.select_set(True)
  uv=obj.data.uv_layers.get('AO_Atlas') or obj.data.uv_layers.new(name='AO_Atlas')
  obj.data.uv_layers.active=uv
 bpy.context.view_layer.objects.active=objects[0]
 bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
 bpy.ops.uv.smart_project(angle_limit=math.radians(66),island_margin=.002,area_weight=.15,correct_aspect=True,scale_to_bounds=True)
 bpy.ops.uv.pack_islands(rotate=True,margin=.002)
 bpy.ops.object.mode_set(mode='OBJECT')
 print('AO_UV_READY',tag,len(objects),'seconds=',round(time.time()-started,1),flush=True)
 atlas=bpy.data.images.new(tag+' contact AO',width=size,height=size,alpha=False);atlas.colorspace_settings.name='Non-Color'
 bake=bpy.data.materials.new(tag+' AO bake');bake.use_nodes=True;nodes=bake.node_tree.nodes;nodes.clear()
 ao=nodes.new('ShaderNodeAmbientOcclusion');ao.samples=16;ao.inputs['Distance'].default_value=.70
 emission=nodes.new('ShaderNodeEmission');bake.node_tree.links.new(ao.outputs['Color'],emission.inputs['Color']);out=nodes.new('ShaderNodeOutputMaterial');bake.node_tree.links.new(emission.outputs['Emission'],out.inputs['Surface'])
 target=nodes.new('ShaderNodeTexImage');target.image=atlas;nodes.active=target;target.select=True
 # One temporary joined mesh avoids rebuilding the whole Cycles scene once per object.
 bpy.ops.object.select_all(action='DESELECT');copies=[]
 for obj in objects:
  copy=obj.copy();copy.data=obj.data.copy();bpy.context.scene.collection.objects.link(copy)
  copy.parent=None;copy.matrix_world=obj.matrix_world.copy();copy.hide_render=False;obj.hide_render=True
  copy.data.materials.clear();copy.data.materials.append(bake);copy.select_set(True);copies.append(copy)
 bpy.context.view_layer.objects.active=copies[0];bpy.ops.object.join();joined=bpy.context.object
 joined.data.uv_layers.active=joined.data.uv_layers.get('AO_Atlas')
 scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=32;scene.render.bake.margin=5;scene.render.bake.use_clear=True;scene.render.bake.use_selected_to_active=False
 bpy.ops.object.bake(type='EMIT')
 bpy.data.objects.remove(joined,do_unlink=True)
 # Release the CPU render session before packing image buffers for glTF.
 scene.render.engine='BLENDER_EEVEE_NEXT'
 atlas.pack();pixels=np.empty(size*size*4,np.float32);atlas.pixels.foreach_get(pixels);pixels=pixels.reshape(-1,4)
 print('AO_BAKED',tag,'range=',float(pixels[:,:3].min()),float(pixels[:,:3].max()),'mean=',float(pixels[:,:3].mean()),flush=True)
 del pixels
 # Keep the editable bake for inspection and a fast exact-source cache.
 os.makedirs(os.path.join(ROOT,'art/bakes'),exist_ok=True);atlas.filepath_raw=os.path.join(ROOT,'art/bakes',tag+'_ao.png');atlas.file_format='PNG';atlas.save();atlas.pack()
 materials={}
 for obj,(original,indices) in saved.items():
  obj.data.materials.clear()
  for m in original:
   if m not in materials:materials[m]=material_copy(m,atlas,'AO_Atlas',tag)[0]
   obj.data.materials.append(materials[m])
  for p,index in zip(obj.data.polygons,indices):p.material_index=index
  obj.data.uv_layers.active_index=0;obj.data.uv_layers[0].active_render=True
 for obj,value in hidden.items():obj.hide_render=value
 bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT,'art',tag+'_lit.blend'))
 export(tag,output)
 print('ENVIRONMENT_POLISH_DONE',tag,'seconds=',round(time.time()-started,1),flush=True)

polish(os.path.join(ROOT,'art/two_storey_faces.blend'),'TwoStoreyHouse','House',1024,os.path.join(ROOT,'assets/models/two_storey.glb'),True)
polish(os.path.join(ROOT,'art/apartment_cast.blend'),'ApartmentEnvironment','Apartment',512,os.path.join(ROOT,'assets/models/apartment_cast.glb'))
