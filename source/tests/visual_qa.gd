extends SceneTree
var folder = OS.get_environment("PAKOSTI_QA_DIR")
func _init():
	if folder == "": folder = ProjectSettings.globalize_path("res://../evidence/")
	if not folder.ends_with("/"): folder += "/"
	DirAccess.make_dir_recursive_absolute(folder)
func _initialize():call_deferred("capture")
func capture():
	var g=load("res://scenes/main_3d.tscn").instantiate()
	root.add_child(g)
	await process_frame
	g.start_level(0)
	g.set_process(false)
	for i in range(8):await process_frame
	await snap("gameplay",g)
	g.hud.visible=false
	g.camera_3d.size=12.5
	g.camera_3d.position=Vector3(10,14,16)
	g.camera_3d.look_at(Vector3(0,0,0))
	await snap("apartment",g)
	g.player_pos=Vector2(-4.9,-.85)
	g.set_actor_position(g.actor,g.player_pos)
	g.actor.rotation.y=.2
	g.enemies[0]["node"].position=Vector3(-3,-0.0,-.85)
	g.enemies[0]["node"].rotation.y=-.3
	g.camera_3d.projection=Camera3D.PROJECTION_PERSPECTIVE
	g.camera_3d.fov=43
	g.camera_3d.position=Vector3(-1.8,3.5,4.9)
	g.camera_3d.look_at(Vector3(-4.0,1.15,-.85))
	await snap("cast",g)
	for lv in range(1,4):
		g.camera_3d.projection=Camera3D.PROJECTION_ORTHOGONAL
		g.camera_3d.size=8.8
		g.start_level(lv)
		g.hud.visible=true
		g.set_process(false)
		await snap("level_%d"%(lv+1),g)
	g.queue_free()
	await process_frame
	await process_frame
	quit()
func snap(name:String,g):
	for i in range(5):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+name+".png")
	print("CAPTURE_OK ",name," draws=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," objects=",Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)," primitives=",Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
