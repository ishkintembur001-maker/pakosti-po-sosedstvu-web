extends SceneTree
## Regression test for native doors, searchable details and two-way stairs.
var failures:int=0
func check(ok:bool,reason:String)->void:
 if not ok:
  failures+=1
  push_error("HOUSE_INTERACTIONS_QA_FAILED: "+reason)
func _initialize()->void:call_deferred("run")
func run()->void:
 var game=load("res://scenes/house.tscn").instantiate()
 root.add_child(game)
 await process_frame
 if not is_instance_valid(game) or not game.has_meta("user_models_installed"):
  check(false,"Original five owner GLBs were not loaded")
  quit(1);return
 game.set_process(false)
 check(game.interactables.doors.size()==4,"Expected four doors across two floors")
 check(game.interactables.caches.size()==6,"Expected six searchable spots")
 var door=game.interactables.doors[0]
 game.floor_id=0
 game.player_pos=game.interactables.approach(door.pos,Vector2(-6,1.1))
 check(not door.open,"A new door should start closed")
 check(game.interactables.toggle(0),"Manual door open failed")
 check(door.open and not game.interactables.opaque_at(door.pos,0),"Open door blocks line of sight")
 game.player_pos=Vector2(-6,1.1)
 game.neighbor_pos=Vector2(5,1.1)
 check(game.interactables.set_open(door,false),"Empty door cannot be closed")
 check(game.interactables.opaque_at(door.pos,0),"Closed door does not block sight")
 check(game.interactables.obstructs_step(door.pos,0),"Approach did not trigger automatic door opening")
 check(door.open,"Door was not opened for the approaching actor")
 game.start_case(0)
 var cache=game.interactables.caches[0]
 game.player_pos=cache.pos
 var original_count:int=game.inventory[cache.kind]
 check(game.interactables.search(0),"Searching furniture failed")
 check(game.interactables.found_details==1,"Found details counter not updated")
 check(game.inventory[cache.kind]==original_count+1,"Found usable item not added to bag")
 check(not game.interactables.search(0),"The same drawer could be looted twice")
 game.player_pos=game.STAIR_ENTRY_LOWER
 check(game.near_stair(),"Lower staircase entrance is unreachable")
 game.start_climb()
 check(game.climbing>0,"Ascending failed to start")
 game.safe_time=999
 for frame in range(195):game._process(1.0/60)
 check(game.floor_id==1 and game.climbing<=0,"The hero did not reach upper floor")
 check(game.player_pos.distance_to(game.STAIR_ENTRY_UPPER)<.01,"Wrong upper landing")
 check(not game.blocked(game.player_pos,1),"Upper landing is blocked")
 game.start_climb()
 check(game.climbing>0 and game.climb_to==0,"Descending failed to start")
 for frame in range(195):game._process(1.0/60)
 check(game.floor_id==0 and game.climbing<=0,"The hero did not reach lower floor")
 check(game.player_pos.distance_to(game.STAIR_ENTRY_LOWER)<.01,"Wrong lower landing")
 for mission in range(24):
  game.start_case(mission)
  check(game.interactables.caches.size()==6,"Missing searchable spots in mission %d"%mission)
  check(game.interactables.found_details==0,"Search state leaked between missions")
  check(game.interactables.doors.all(func(d):return not d.open),"Door states did not reset")
 check(game.CASES.size()==24,"24 missions changed unexpectedly")
 game.queue_free()
 await process_frame
 print("HOUSE_INTERACTIONS_QA_DONE failures=",failures)
 quit(1 if failures else 0)
