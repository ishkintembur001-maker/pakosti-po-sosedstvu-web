extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/house.tscn").instantiate();root.add_child(g);await process_frame;g.safe_time=9999
 for smooth in [false,true]:
  g.set_quality(not smooth)
  for i in range(15):await process_frame
  var start=Time.get_ticks_usec();var max_ms=0.0;var last=start
  for i in range(90):
   await process_frame;var now=Time.get_ticks_usec();max_ms=maxf(max_ms,(now-last)/1000.0);last=now
  print("HOUSE_PERF ",JSON.stringify({"smooth":smooth,"fps":snappedf(90.0/((Time.get_ticks_usec()-start)/1000000.0),.1),"max_frame_ms":snappedf(max_ms,.1),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"vram_mb":snappedf(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1048576.0,.1),"renderer":"llvmpipe software OpenGL; not a phone benchmark"}))
 g.queue_free();await process_frame;await process_frame;quit()
