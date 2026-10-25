extends SceneTree
func _initialize():call_deferred("run")
func run():
 var rig=load("res://tests/hero_rebuilt_gait.gd").new();root.add_child(rig);rig.set_process(false)
 var source_speed=20.0/.28
 var worst=0.0;var previous=[null,null];var errors=0
 for i in 240:
  rig.age=i/120.0;var transforms=rig.pose_transforms();var phase=fposmod(rig.age/.56,1.0)
  for leg in 2:
   var t=fposmod(phase+leg*.5,1.0)
   if t>=.5:previous[leg]=null;continue
   var world=(transforms[5+leg]*rig.joints[5+leg]).x+source_speed*rig.age
   if previous[leg]!=null:worst=maxf(worst,absf(world-previous[leg]))
   previous[leg]=world
  rig.update_shorts(transforms)
  for index in [1,3]:
   var rest=rig.thigh_sources[index][Mesh.ARRAY_VERTEX]
   var result=rig.parts[index].surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
   for j in rest.size():
    if rest[j].y<=145:
     var expected=transforms[0]*Vector2(rest[j].x,rest[j].y)
     if expected.distance_to(Vector2(result[j].x,result[j].y))>.001:errors+=1
 if worst>.001:errors+=1
 print("REBUILT_STRIDE source_speed=",source_speed," support_frame_drift=",worst," waist_errors=",errors)
 print("Scope: study gait only; this speed is NOT the current gameplay movement speed.")
 rig.queue_free();await process_frame;quit(errors)
