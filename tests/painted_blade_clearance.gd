extends SceneTree
func _initialize():call_deferred("run")
func run():
 var rig=load("res://scripts/animation/painted_rig/combo.gd").new();root.add_child(rig);rig.set_process(false);rig.attack_index=-1;rig.motion_amount=0;rig.contact_enabled=true
 var worst=-INF
 for i in 23:
  rig.age=i/120.0;rig.landing_squash=5*sin(PI*clampf((.18-i/120.0)/.18,0,1))
  var pose=rig.pose_transforms()
  worst=maxf(worst,(pose[7]*Vector2(120,168)).y-199)
 print("PAINTED_LANDING blade_tip_relative_floor=",worst)
 rig.queue_free();await process_frame;quit(0 if worst<0 else 1)
