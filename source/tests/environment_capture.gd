extends SceneTree
var g
var folder:String
func _initialize():call_deferred("run")
func snap(name:String):
 for i in range(5):await process_frame
 await RenderingServer.frame_post_draw
 var image=root.get_texture().get_image();image.save_png(folder+name+".png")
 print("ENV_CAPTURE_OK ",name," image=",image.get_size()," quality=",g.quality)
func view_at(target:Vector3,offset:Vector3,size:float):
 g.camera.projection=Camera3D.PROJECTION_ORTHOGONAL;g.camera.size=size;g.camera.position=target+offset;g.camera.look_at(target)
func run():
 root.size=Vector2i(1280,720)
 folder=ProjectSettings.globalize_path("res://../evidence/environment/");DirAccess.make_dir_recursive_absolute(folder)
 g=load("res://scenes/house.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g._process(0);g.set_quality(true);g.hud.hide()
 for item in g.targets+g.supplies:item.node.hide()
 for actor in [g.hero,g.neighbor]:actor.get_meta("animation_player").speed_scale=0
 for m in g.slice_materials:m.set_shader_parameter("cutoff",99.0)
 view_at(Vector3(0,2.65,0),Vector3(1.6,11.5,21),11.8);await snap("house_detail")
 g.floor_id=0;g.set_slice();view_at(Vector3(-5.1,.9,0),Vector3(1.1,4.7,8),4.6);await snap("living_ao")
 for m in g.slice_materials:m.set_shader_parameter("ao_strength",0.0)
 await snap("living_without_ao")
 for m in g.slice_materials:m.set_shader_parameter("ao_strength",.45)
 view_at(Vector3(-.05,.8,0),Vector3(1.2,4.7,8),4.7);await snap("kitchen_detail")
 g.floor_id=1;g.set_slice();view_at(Vector3(-5.25,4.35,0),Vector3(1.1,4.7,8),4.8);await snap("bedroom_detail")
 g.floor_id=0;g.set_slice();g.set_quality(false);g.hud.show();g.camera.size=7.9;g._process(0);await snap("gameplay_smooth")
 g.queue_free();await process_frame;await create_timer(.2).timeout;quit()
