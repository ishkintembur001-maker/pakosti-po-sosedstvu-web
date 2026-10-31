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
  var limb=actor.find_child("Arm_L*",true,false);p.play("walk");p.seek(0,true);var a=limb.quaternion;p.advance(.25)
  if a.is_equal_approx(limb.quaternion):push_error("Animation did not move shoulder");fail+=1
 g.queue_free();await process_frame;await process_frame;print("ANIMATION_QA failures=",fail);quit(fail)
