extends RefCounted
## Integrates the owner's five GLB models into the existing 24-mission house.
## All five are required. Failed imports leave the original game intact.
const HERO = "res://assets/user_models/hero_rigged.glb"
const NEIGHBOR = "res://assets/user_models/neighbor_rigged.glb"
const LOWER = "res://assets/user_models/house_lower_quality.glb"
const UPPER = "res://assets/user_models/house_upper_quality.glb"
const ROOF = "res://assets/user_models/house_roof_quality.glb"
const PATHS = [HERO, NEIGHBOR, LOWER, UPPER, ROOF]

static func available() -> bool:
 for resource_path in PATHS:
  if not ResourceLoader.exists(resource_path):
   return false
 return true

static func _create_model(resource_path:String) -> Node3D:
 var resource=ResourceLoader.load(resource_path)
 if resource is PackedScene:
  return (resource as PackedScene).instantiate() as Node3D
 return null

static func _find_player(model:Node3D) -> AnimationPlayer:
 var players=model.find_children("*", "AnimationPlayer", true, false)
 if players.size()>0:
  return players[0] as AnimationPlayer
 return null

static func _hide_original_meshes(actor:Node3D) -> void:
 for mesh in actor.find_children("*", "MeshInstance3D", true, false):
  mesh.hide()

static func try_install(game) -> bool:
 if not available():
  return false
 var loaded=[]
 for resource_path in PATHS:
  var model=_create_model(resource_path)
  if model==null:
   for old in loaded:old.free()
   push_warning("Owner GLB import failed: " + resource_path)
   return false
  loaded.append(model)
 var hero_model:Node3D=loaded[0]
 var neighbor_model:Node3D=loaded[1]
 var hero_anim=_find_player(hero_model)
 var neighbor_anim=_find_player(neighbor_model)
 if hero_anim==null or neighbor_anim==null:
  for old in loaded:old.free()
  push_warning("Missing AnimationPlayer in owner characters")
  return false
 if not hero_anim.has_animation("caught_react") or hero_anim.has_animation("catch"):
  for old in loaded:old.free()
  push_warning("Hero GLB has invalid capture-role clips")
  return false
 if not neighbor_anim.has_animation("catch") or neighbor_anim.has_animation("caught_react"):
  for old in loaded:old.free()
  push_warning("Neighbor GLB has invalid capture-role clips")
  return false
 var building=Node3D.new()
 building.name="OwnersHighDetailTwoStoreyHouse"
 building.position.y=game.H
 building.scale=Vector3.ONE * game.H * 2.0
 game.add_child(building)
 for i in range(2,5):
  building.add_child(loaded[i])
  loaded[i].name=["HouseGroundFloor", "HouseSecondFloor", "HouseRoof"][i-2]
 loaded[4].hide()
 _hide_original_meshes(game.hero)
 _hide_original_meshes(game.neighbor)
 game.hero.add_child(hero_model)
 hero_model.name="OwnersHighDetailHero"
 hero_model.position.y=.79
 hero_model.scale=Vector3.ONE*.84
 game.neighbor.add_child(neighbor_model)
 neighbor_model.name="OwnersHighDetailNeighbor"
 neighbor_model.position.y=.91
 neighbor_model.scale=Vector3.ONE*.96
 game.hero.set_meta("animation_player",hero_anim)
 game.neighbor.set_meta("animation_player",neighbor_anim)
 game.environment_root.hide()
 game.set_meta("user_models_installed",true)
 print("OWNER_3D_MODELS_ENABLED: hero, neighbor, both storeys, roof hidden")
 return true

# Use geometry sampled from the real scan. This changes visuals only,
# retaining the existing navigable paths, traps and 24 missions.
const SCAN_SURFACE="res://assets/data/owner_scan_surface.json"
const SCAN_OBSTACLES="res://assets/data/owner_scan_obstacles.json"

static func _grid_data(game,resource_path:String,cache_key:String)->Dictionary:
 if game.has_meta(cache_key):return game.get_meta(cache_key)
 var d:Dictionary={}
 if FileAccess.file_exists(resource_path):
  var v=JSON.parse_string(FileAccess.get_file_as_string(resource_path))
  if v is Dictionary:d=v
 game.set_meta(cache_key,d)
 return d

static func _scan_height(game,p:Vector2,floor:int)->float:
 var d=_grid_data(game,SCAN_SURFACE,"_owner_scan_surface")
 if d.is_empty():return game.floor_height(p,floor)
 var x=clampi(roundi((p.x-float(d.origin[0]))/float(d.cell)),0,int(d.width)-1)
 var z=clampi(roundi((p.y-float(d.origin[1]))/float(d.cell)),0,int(d.height)-1)
 var sample=d.floors[clampi(floor,0,1)][z][x]
 return game.floor_height(p,floor) if sample==null else float(sample)

static func _clear_cell(d:Dictionary,floor:int,x:int,z:int)->bool:
 if x<0 or z<0 or x>=int(d.width) or z>=int(d.height):return false
 return String(d.floors[clampi(floor,0,1)][z])[x]=="0"

static func _safe_visual_position(game,p:Vector2,floor:int)->Vector2:
 var d=_grid_data(game,SCAN_OBSTACLES,"_owner_scan_obstacles")
 if d.is_empty():return p
 var size=float(d.cell)
 var x=roundi((p.x-float(d.origin[0]))/size)
 var z=roundi((p.y-float(d.origin[1]))/size)
 var best=p
 var threshold=.68
 for dz in range(-3,4):
  for dx in range(-3,4):
   var xx=x+dx;var zz=z+dz;var safe=true
   for nz in range(-1,2):
    for nx in range(-1,2):
     if not _clear_cell(d,floor,xx+nx,zz+nz):safe=false;break
    if not safe:break
   if not safe:continue
   var candidate=Vector2(float(d.origin[0])+xx*size,float(d.origin[1])+zz*size)
   var distance=p.distance_to(candidate)
   if distance<threshold:best=candidate;threshold=distance
 return best

static func update_visual_grounding(game)->void:
 if not game.has_meta("user_models_installed"):return
 var hero=game.hero.find_child("OwnersHighDetailHero",true,false)
 var neighbor=game.neighbor.find_child("OwnersHighDetailNeighbor",true,false)
 for data in [
  {"actor":game.hero,"model":hero,"bottom":-.951712*.84},
  {"actor":game.neighbor,"model":neighbor,"bottom":-.9522*.96}
 ]:
  var model=data.model as Node3D
  if model==null:continue
  var actor=data.actor as Node3D
  var p=Vector2(actor.position.x,actor.position.z)
  var blend=clampf((actor.position.y-.25)/game.H,0.0,1.0)
  var floor_y=lerpf(_scan_height(game,p,0),_scan_height(game,p,1),blend)
  var target_y=floor_y-actor.position.y-float(data.bottom)+.035
  model.position.y=lerpf(model.position.y,target_y,.35)
  var safe=_safe_visual_position(game,p,1 if blend>.5 else 0)
  model.position.x=lerpf(model.position.x,safe.x-p.x,.3)
  model.position.z=lerpf(model.position.z,safe.y-p.y,.3)
