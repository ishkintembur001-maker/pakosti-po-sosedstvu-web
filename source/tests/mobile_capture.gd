extends SceneTree
func _initialize():call_deferred("run")
func snap(name:String):
 for i in range(4):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../mobile-evidence/"+name+".png"))
func run():
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../mobile-evidence/"))
 root.size=Vector2i(1169,540)
 var menu=load("res://scenes/release_menu.tscn").instantiate();root.add_child(menu);await process_frame;await snap("native_menu")
 menu.start_house(0);var g=menu.active_game;g.safe_time=999;await snap("native_game")
 g.hud.show_pause();await snap("native_pause");menu.return_menu();menu.open_cases();await snap("native_cases")
 menu.queue_free();await process_frame;await create_timer(.2).timeout;quit()
