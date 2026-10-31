extends SceneTree
var failures = 0
func _initialize():call_deferred("verify")
func check(ok:bool,text:String):
	if not ok:
		push_error(text)
		failures += 1
func touch(i:int,point:Vector2,pressed:bool,g):
	var e=InputEventScreenTouch.new();e.index=i;e.position=point;e.pressed=pressed;g._input(e)
func verify():
	var g=load("res://scenes/main_3d.tscn").instantiate()
	root.add_child(g)
	await process_frame
	for lv in range(4):
		g.start_level(lv)
		check(g.imported_world!=null,"Missing Blender world")
		for item in g.supply_items:
			g.player_pos=Vector2(-5.6,2.2)
			g.plan_walk(item["pos"],0,g.supply_items.find(item))
			check(g.auto_move and not g.walk_path.is_empty(),"Unreachable supply on level %d"%lv)
			g.player_pos=item["pos"];g.on_action()
			var trap=g.traps[item["kind"]]
			g.plan_walk(trap["pos"],1,g.traps.find(trap))
			check(g.auto_move and not g.walk_path.is_empty(),"Unreachable trap on level %d"%lv)
			g.player_pos=trap["pos"];g.on_action();g.finish_trap(trap,g.enemies[0])
		check(g.score==g.traps.size() and g.state in [2,4],"Episode victory failed")
		print("ALL_PRANKS_AND_NAVIGATION_OK level=",lv+1)
	g.start_level(0)
	g.auto_move=false
	touch(0,g.STICK_CENTER+Vector2(40,0),true,g)
	check(g.stick_finger==0 and g.joystick_vector().x>.6,"Touch joystick failed")
	touch(1,Vector2(849,490),true,g)
	touch(1,Vector2(849,490),false,g)
	check(g.stick_finger==0 and g.joystick_vector().x>.6,"Second finger action cancelled joystick")
	var drag=InputEventScreenDrag.new();drag.index=0;drag.position=g.STICK_CENTER+Vector2(300,-300);g._input(drag)
	check(is_equal_approx(g.joystick_vector().length(),1),"Joystick must clamp diagonal speed")
	touch(0,g.STICK_CENTER,false,g)
	check(g.joystick_vector()==Vector2.ZERO,"Joystick stuck after release")
	# Explicit device-size resize smoke checks. Physical Safari performance needs a real iPhone.
	for size in [Vector2i(844,390),Vector2i(667,375),Vector2i(390,844)]:
		root.size=size
		await process_frame
		check(root.get_visible_rect().size.x>0,"Invalid viewport after resize")
		print("VIEWPORT_RESIZE_OK ",size," logical=",root.get_visible_rect().size)
	for sound in [g.sfx_pickup,g.sfx_arm,g.sfx_prank,g.sfx_caught,g.sfx_victory]: sound.stop()
	g.queue_free()
	await process_frame
	await process_frame
	print("MOBILE_MULTITOUCH_OK")
	await create_timer(0.15).timeout
	quit(1 if failures > 0 else 0)
