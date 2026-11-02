extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/house.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false)
 var fail=0
 for actor in [g.hero,g.neighbor]:
  if not actor.has_meta("animation_player"):push_error("No animation player");fail+=1;continue
  var p:AnimationPlayer=actor.get_meta("animation_player")
  print("CAST_CLIPS ",actor.name," ",p.get_animation_list())
  for clip in ["idle","walk","sneak","run","pickup","plant_trap","react_slip","react_surprise","celebrate"]:
   if not p.has_animation(clip):push_error("Missing clip "+clip);fail+=1;continue
   p.play(clip);p.advance(.17)
  var special="caught_react" if actor==g.hero else "catch"
  var forbidden="catch" if actor==g.hero else "caught_react"
  if not p.has_animation(special):push_error("Missing role-specific clip "+special);fail+=1
  if p.has_animation(forbidden):push_error("Forbidden capture clip on actor "+forbidden);fail+=1
  # Rigged owner GLBs use Skeleton3D; original low-poly actors use pivot nodes.
  var skeletons=actor.find_children("*","Skeleton3D",true,false)
  if not skeletons.is_empty():
   var skeleton=skeletons[0] as Skeleton3D
   if skeleton.get_bone_count()!=17:push_error("Owner GLB has wrong bone count");fail+=1
   var bone_id=skeleton.find_bone("LeftUpperArm")
   if bone_id<0:push_error("Left shoulder bone missing");fail+=1;continue
   p.play("walk");p.seek(0,true);p.advance(0)
   var before=skeleton.get_bone_pose_rotation(bone_id)
   p.seek(p.get_animation("walk").length*.25,true);p.advance(0)
   if before.is_equal_approx(skeleton.get_bone_pose_rotation(bone_id)):
    push_error("Skinned shoulder is not animated");fail+=1
  else:
   var limb=actor.find_child("Arm_L*",true,false)
   if limb==null:push_error("Old shoulder pivot missing");fail+=1;continue
   p.play("walk");p.seek(0,true);var before=limb.quaternion;p.advance(.25)
   if before.is_equal_approx(limb.quaternion):push_error("Animation did not move shoulder");fail+=1
   # The stock cast must have working elbow/wrist actions, not rigid hands.
   var elbow=actor.find_child("Elbow_L*",true,false) as Node3D
   var wrist=actor.find_child("Wrist_L*",true,false) as Node3D
   if elbow==null or wrist==null:
    push_error("Missing independent elbow/wrist in "+actor.name);fail+=1;continue
   p.play("pickup");p.seek(0.0,true)
   var bend_before=elbow.rotation.x
   p.seek(p.get_animation("pickup").length*.5,true)
   if absf(elbow.rotation.x-bend_before)<.20:
    push_error("Picking up an item did not bend the elbow");fail+=1
   p.play("walk");p.seek(0.0,true)
   var wrist_before=wrist.rotation.z
   p.seek(p.get_animation("walk").length*.25,true)
   if absf(wrist.rotation.z-wrist_before)<.025:
    var wrist_animation_paths=[]
    for track_id in range(p.get_animation("walk").get_track_count()):
     var track_path=String(p.get_animation("walk").track_get_path(track_id))
     if track_path.contains("Wrist"):wrist_animation_paths.append(track_path)
    print("WRIST_QA_DIAGNOSTIC ",actor.name," before=",wrist_before," after=",wrist.rotation.z," tracks=",wrist_animation_paths)
    push_error("Walking did not animate the wrist");fail+=1
 g.queue_free();await process_frame;await process_frame;print("ANIMATION_QA failures=",fail);quit(fail)
