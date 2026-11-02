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
