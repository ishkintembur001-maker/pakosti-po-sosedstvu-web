extends RefCounted
# Shared by the house and all four original episodes.
static func apply(actor:Node3D,clock:float,enemy:bool,celebrate:bool=false):
 if not actor.has_meta("face_meshes"):
  actor.set_meta("face_meshes",actor.find_children("*Face_Anatomy*","MeshInstance3D",true,false))
 var phase=fmod(clock+(3.1 if enemy else 1.7),5.7)
 var blink=maxf(0,1-absf(phase-.09)/.09)
 for face in actor.get_meta("face_meshes"):
  for i in range(face.mesh.get_blend_shape_count()):
   var name=face.mesh.get_blend_shape_name(i)
   var weight=blink if name=="Blink" else (.65 if name=="Frown" and enemy else (.85 if name=="Smile" and celebrate else (.2 if name=="Smile" and not enemy else 0)))
   if absf(face.get_blend_shape_value(i)-weight)>.015:face.set_blend_shape_value(i,weight)
