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
 g.queue_free();await process_frame;await process_frame;print("ANIMATION_QA failures=",fail);quit(fail)
