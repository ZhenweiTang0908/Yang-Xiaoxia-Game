extends SceneTree
func _initialize():
 var rig=load("res://tests/hero_layer_study.gd").new();rig.posing=true
 var errors=0
 for i in 120:
  rig.age=i/60.0;var transforms=rig.pose_transforms()
  for pair in [[2,5],[4,6]]:
   var ankle=rig.joints[pair[1]]
   if (transforms[pair[0]]*ankle).distance_to(transforms[pair[1]]*ankle)>.0001:errors+=1
   if absf(transforms[pair[1]].get_rotation())>.0001:errors+=1
 print("FOOT_LAYER_ALIGNMENT samples=240 errors=",errors)
 rig.free();quit(errors)
