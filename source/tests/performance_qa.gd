extends SceneTree
func _initialize():call_deferred("measure")
func measure():
	var g=load("res://scenes/main_3d.tscn").instantiate()
	root.add_child(g)
	await process_frame
	for lv in [0,3]:
		g.start_level(lv)
		g.safe_time=1000
		for i in range(30):await process_frame
		var start=Time.get_ticks_usec()
		var worst=0
		var previous=start
		for i in range(120):
			await process_frame
			var now=Time.get_ticks_usec()
			worst=max(worst,now-previous);previous=now
		var elapsed=(Time.get_ticks_usec()-start)/1000000.0
		print("PERF_QA ",JSON.stringify({"smooth_mode":g.performance_mode,"level":lv+1,"fps":snapped(120.0/elapsed,.1),"worst_frame_ms":snapped(worst/1000.0,.1),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"video_memory_mb":snapped(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1048576,.1),"renderer":"GL Compatibility / llvmpipe software"}))
	for p in [g.sfx_pickup,g.sfx_arm,g.sfx_prank,g.sfx_caught,g.sfx_victory]:p.stop()
	g.queue_free()
	await create_timer(.15).timeout
	quit()
