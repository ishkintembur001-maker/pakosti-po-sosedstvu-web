extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/house.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.hud.hide()
 g.hero.position=Vector3(-4.7,.2,1);g.hero.rotation.y=.1;g.neighbor.position=Vector3(-3,.2,1);g.neighbor.rotation.y=-.1
 g.camera.projection=Camera3D.PROJECTION_PERSPECTIVE;g.camera.fov=43;g.camera.position=Vector3(-3.8,2.2,6.5);g.camera.look_at(Vector3(-3.85,1.25,1))
 for t in g.targets:t.node.hide()
 for s in g.supplies:s.node.hide()
 var folder=ProjectSettings.globalize_path("res://../evidence/poses/");DirAccess.make_dir_recursive_absolute(folder)
 for clip in ["idle","walk","sneak","run","pickup","plant_trap","react_slip","react_surprise","celebrate"]:
  for actor in [g.hero,g.neighbor]:
   var p:AnimationPlayer=actor.get_meta("animation_player");p.play(clip);p.advance(0);p.seek(p.get_animation(clip).length*.35,true);p.advance(0);p.speed_scale=0
  for i in range(3):await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(folder+clip+".png")
 # Review motion at multiple phases; single still frames cannot reveal limb drift.
 for phase in [0.15,0.35,0.55,0.75,0.95]:
  for actor in [g.hero,g.neighbor]:
   var animator:AnimationPlayer=actor.get_meta("animation_player")
   animator.play("walk")
   animator.seek(animator.get_animation("walk").length*phase,true)
   animator.advance(0)
   animator.speed_scale=0
  for frame in range(2):await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(folder+"walk_phase_%02d.png"%int(phase*100))
 for phase in [0.2,0.45,0.7]:
  for actor in [g.hero,g.neighbor]:
   var animator:AnimationPlayer=actor.get_meta("animation_player")
   var role_clip="caught_react" if actor==g.hero else "catch"
   animator.play(role_clip)
   animator.seek(animator.get_animation(role_clip).length*phase,true)
   animator.advance(0)
   animator.speed_scale=0
  for frame in range(2):await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(folder+"capture_phase_%02d.png"%int(phase*100))
 g.queue_free();await process_frame;await process_frame;quit()
