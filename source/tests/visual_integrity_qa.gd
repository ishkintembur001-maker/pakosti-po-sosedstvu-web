extends SceneTree
# Evaluate actual imported Godot actors, not screenshots or synthetic mesh assumptions.
var failures=0
func check(ok:bool,reason:String)->void:
 if not ok:
  failures+=1
  push_error("VISUAL_INTEGRITY_FAIL "+reason)
func _initialize()->void:
 call_deferred("run")
func run()->void:
 var scene=load("res://scenes/house.tscn").instantiate()
 root.add_child(scene)
 await process_frame
 scene.set_process(false)
 check(scene.CASES.size()==24,"All 24 mission entries must survive import")
 check(scene.environment_root!=null,"Original house root is missing")
 check(scene.environment_root.find_child("*04_Upper_bedroom*",true,false)!=null,"Upper storey must not be removed")
 for floor_index in range(2):
  scene.floor_id=floor_index
  scene.set_slice()
  for material in scene.slice_materials:
   check(float(material.get_shader_parameter("cutoff"))>90.0,"Both floors must remain visible")
  scene.player_pos=Vector2(-4.7,1.0) if floor_index==0 else Vector2(5.0,-2.15)
  scene.action_time=0
  scene.move_player(0.0)
  var floor_y=scene.floor_height(scene.player_pos,floor_index)
  var expected=floor_y-.015*scene.hero.scale.y
  check(absf(scene.hero.position.y-expected)<.025,"Hero origin floats relative to floor "+str(floor_index))
  check(scene.hero.position.is_finite(),"Invalid hero root position on floor "+str(floor_index))
  scene.update_contact(scene.hero_contact,scene.hero,scene.player_pos,floor_index,true)
  check(absf(scene.hero_contact.position.y-floor_y-.004)<.025,"Contact shadow is not grounded on floor "+str(floor_index))
 for actor in [scene.hero,scene.neighbor]:
  var title="hero" if actor==scene.hero else "neighbor"
  var animator=actor.get_meta("animation_player") as AnimationPlayer
  check(animator!=null,"Missing animation player on "+title)
  if animator==null:continue
  var offensive="catch" if actor==scene.neighbor else "caught_react"
  var forbidden="caught_react" if actor==scene.neighbor else "catch"
  check(animator.has_animation(offensive),"Missing proper capture role "+title)
  check(not animator.has_animation(forbidden),"Wrong capture role on "+title)
  var clips=["idle","walk","sneak","run","pickup","plant_trap","react_slip","react_surprise","celebrate",offensive]
  var standing=actor.position
  for clip in clips:
   if not animator.has_animation(clip):
    check(false,"Missing clip "+title+"/"+clip)
    continue
   var animation=animator.get_animation(clip)
   check(animation.length>0,"Animation has zero duration "+title+"/"+clip)
   animator.play(clip)
   for phase in [0.05,0.25,0.5,0.75,0.95]:
    animator.seek(animation.length*phase,true)
    animator.advance(0)
    check(actor.position.distance_to(standing)<.1,"Whole actor drifting under "+title+"/"+clip)
    for limb_name in ["Arm_L*","Arm_R*","Legs_L*","Legs_R*"]:
     var limb=actor.find_child(limb_name,true,false)
     check(limb is Node3D,"Missing articulated limb "+title+"/"+limb_name)
     if limb is Node3D:
      check(limb.position.is_finite() and limb.rotation.is_finite(),"Non-finite limb transform "+title+"/"+clip+"/"+limb_name)
      check(limb.rotation.length()<2.6,"Limb twists past safe angle "+title+"/"+clip+"/"+limb_name)
   animator.stop()
  var meshes=actor.find_children("*","MeshInstance3D",true,false)
  check(meshes.size()>10,"Character lost important mesh components "+title)
  var geometry_errors=0
  for obj in meshes:
   if obj.mesh==null:
    geometry_errors+=1
    continue
   var bounds=obj.mesh.get_aabb()
   if not bounds.position.is_finite() or not bounds.size.is_finite() or bounds.size.length()>50:
    geometry_errors+=1
  check(geometry_errors==0,"Invalid or stretched mesh bounds "+title+" count="+str(geometry_errors))
 scene.start_case(0)
 scene.safe_time=0
 scene.begin_capture()
 check(scene.capture_time>0 and scene.lives==2,"Neighbor catch must cost exactly one life")
 # The catch lasts 1.8 seconds. 120 frames at 60 Hz cover the full clip.
 for frame in range(120):
  scene.tick_capture(1.0/60.0)
  check(scene.lives==2,"Capture animation removed extra lives")
  if scene.capture_time>0:
   var hero_player=scene.hero.get_meta("animation_player") as AnimationPlayer
   var neighbor_player=scene.neighbor.get_meta("animation_player") as AnimationPlayer
   check(hero_player.current_animation=="caught_react","Hero performs offensive catch instead of defensive reaction")
   check(neighbor_player.current_animation=="catch","Neighbor fails to perform capture")
 check(scene.capture_time==0 and scene.player_pos==scene.EXIT_POS,"Capture failed to finish safely")
 scene.queue_free()
 await process_frame
 await process_frame
 print("VISUAL_INTEGRITY_QA failures=",failures)
 quit(1 if failures else 0)
