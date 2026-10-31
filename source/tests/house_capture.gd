extends SceneTree
func _initialize():call_deferred("run")
func shot(name:String):
 for i in range(5):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../evidence/"+name+".png"))
func run():
 var menu=load("res://scenes/release_menu.tscn").instantiate();root.add_child(menu);await process_frame
 await shot("release_menu")
 menu.menu_action(1);await process_frame
 var g=menu.active_game;g.set_process(false);g.camera.size=12;g.camera.position=Vector3(0,12,20);g.camera.look_at(Vector3(0,2.5,0));for m in g.slice_materials:m.set_shader_parameter("cutoff",99.0)
 await shot("new_house_overview")
 g.set_slice();g._process(0);await shot("new_house_gameplay")
 g.hud.hide();g.hero.position=Vector3(-4.7,.2,1.0);g.hero.rotation.y=.2;g.neighbor.position=Vector3(-3.1,.2,1.0);g.neighbor.rotation.y=-.15;g.camera.projection=Camera3D.PROJECTION_PERSPECTIVE;g.camera.fov=43;g.camera.position=Vector3(-3.9,2.15,6.3);g.camera.look_at(Vector3(-4,1.3,1));await shot("new_house_cast")
 menu.return_menu();await process_frame;menu.queue_free();await process_frame;quit()
