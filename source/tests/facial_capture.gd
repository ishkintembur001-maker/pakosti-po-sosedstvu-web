extends SceneTree
func _initialize():call_deferred("run")
func run():
 var folder=ProjectSettings.globalize_path("res://../evidence/faces/");DirAccess.make_dir_recursive_absolute(folder)
 var g=load("res://scenes/house.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.hud.hide()
 for t in g.targets:t.node.hide()
 for t in g.supplies:t.node.hide()
 g.hero.position=Vector3(-4.7,.2,1);g.hero.rotation.y=0;g.neighbor.position=Vector3(-4.7,.2,1);g.neighbor.rotation.y=0
 g.camera.projection=Camera3D.PROJECTION_PERSPECTIVE;g.camera.fov=38
 for actor in [g.hero,g.neighbor]:
  g.hero.visible=actor==g.hero;g.neighbor.visible=actor==g.neighbor
  actor.get_meta("animation_player").speed_scale=0
  var face=actor.find_child("*Face_Anatomy*",true,false)
  for pose in ["Neutral","Smile","Frown","Blink"]:
   for i in range(face.mesh.get_blend_shape_count()):face.set_blend_shape_value(i,1 if String(face.mesh.get_blend_shape_name(i))==pose else 0)
   var target=actor.position+Vector3(0,1.6,0);g.camera.position=target+Vector3(.35,.1,2.7);g.camera.look_at(target)
   for i in range(3):await process_frame
   await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(folder+actor.name+"_"+pose+".png")
 g.queue_free();await process_frame;await create_timer(.2).timeout;quit()
