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
   var p:AnimationPlayer=actor.get_meta("animation_player");p.play(clip);p.seek(.33,true);p.speed_scale=0
  for i in range(3):await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(folder+clip+".png")
 g.queue_free();await process_frame;await process_frame;quit()
