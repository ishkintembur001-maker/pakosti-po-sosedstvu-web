extends SceneTree
var failures=0
func check(ok:bool,msg:String):
 if not ok:push_error(msg);failures+=1
func _initialize():call_deferred("run")
func run():
 var menu=load("res://scenes/release_menu.tscn").instantiate();root.add_child(menu);await process_frame;menu.start_house(0);await process_frame
 var g=menu.active_game;g.set_process(false)
 for dims in [Vector2i(960,540),Vector2i(1169,540),Vector2i(1289,540)]:
  root.size=dims;await process_frame;g.hud.layout()
  var r=g.hud.action.get_global_rect();check(r.position.x>dims.x*.6 and r.end.x<dims.x,"Action button off safe edge")
  check(r.size.y>=70,"Exit action too small");check(not g.hud.action.visible,"Exit button must stay hidden before completion")
  check(g.hud.top.position.x>=28,"Title outside safe area")
  print("MOBILE_LAYOUT_OK ",dims," exit_button=",r)
 # Pause freezes real patrol and timer; GUI resumes without losing scene.
 g.hud.show_pause();var pos=g.neighbor_pos;var time=g.elapsed;g._process(3)
 check(g.paused and g.neighbor_pos==pos and g.elapsed==time,"Pause advanced gameplay")
 g.hud.pause_panel.free();g.hud.pause_panel=null;g.set_paused(false)
 # Clicking an actual pickup projects its world marker, routes and collects.
 g.start_case(0);g._process(0);var item=g.supplies[0];var point=g.camera.unproject_position(Vector3(item.pos.x,.55,item.pos.y));g.click_world(point)
 check(g.pending_target!=Vector2.INF,"Touch target not selected")
 for i in range(600):g.action_time=maxf(0,g.action_time-1.0/60);g.move_player(1.0/60)
 check(item.taken,"Tap-to-collect did not finish")
 # Rotation gate freezes the house and restores its prior process mode.
 var shell=root.get_node_or_null("MobileShell")
 if shell:
  root.size=Vector2i(960,2078);await process_frame;shell._process(0)
  check(shell.overlay.visible and g.process_mode==Node.PROCESS_MODE_DISABLED,"Portrait did not gate gameplay")
  root.size=Vector2i(1169,540);await process_frame;shell._process(0)
  check(not shell.overlay.visible and g.process_mode!=Node.PROCESS_MODE_DISABLED,"Rotation did not restore game")
 menu.return_menu();menu.queue_free();await process_frame;await create_timer(.2).timeout
 print("MOBILE_LAYOUT_QA failures=",failures);quit(1 if failures else 0)
