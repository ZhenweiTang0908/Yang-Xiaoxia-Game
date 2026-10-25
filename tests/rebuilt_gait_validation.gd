extends SceneTree
func _initialize():call_deferred("run")
func run():
 var rig=load("res://tests/hero_rebuilt_gait.gd").new();root.add_child(rig);rig.set_process(false)
 var errors=0;var max_ground_error=0.0
 for i in 120:
  rig.age=i/120.0;var transforms=rig.pose_transforms();var phase=fposmod(rig.age/.56,1.0)
  for leg in 2:
   var thigh=1+leg*2;var calf=thigh+1;var foot=5+leg
   if (transforms[thigh]*rig.joints[calf]).distance_to(transforms[calf]*rig.joints[calf])>.001:errors+=1
   if (transforms[calf]*rig.joints[foot]).distance_to(transforms[foot]*rig.joints[foot])>.001:errors+=1
   if fposmod(phase+leg*.5,1.0)<.5:
    var ground=(transforms[foot]*rig.joints[foot]).y+rig.soles[leg]
    max_ground_error=maxf(max_ground_error,absf(ground-199))
 if max_ground_error>.01:errors+=1
 print("REBUILT_GAIT samples=240 max_support_ground_error=",max_ground_error," errors=",errors)
 rig.queue_free();await process_frame;quit(errors)
