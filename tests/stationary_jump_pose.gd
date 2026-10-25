extends SceneTree
func _initialize():call_deferred("run")
func run():
 var rig=load("res://scripts/animation/painted_rig/combo.gd").new();root.add_child(rig)
 rig.set_process(false);rig.attack_index=-1;rig.motion_amount=0;rig.contact_enabled=false;rig.phase_override=.55
 rig.air_pose=0
 var rest=rig.pose_transforms()
 rig.air_pose=1
 var airborne=rig.pose_transforms()
 var ok=true
 for leg in 2:
  var foot=5+leg
  var lift=(rest[foot]*rig.joints[foot]).y-(airborne[foot]*rig.joints[foot]).y
  print("stationary jump leg ",leg," lift=",lift)
  ok=ok and lift>2
  var thigh=1+leg*2;var calf=thigh+1
  ok=ok and (airborne[thigh]*rig.joints[calf]).distance_to(airborne[calf]*rig.joints[calf])<.001
 # Face, collar and torso keep their approved transform during the tuck.
 ok=ok and rest[0].is_equal_approx(airborne[0])
 print("STATIONARY_JUMP ","PASS" if ok else "FAIL")
 rig.queue_free();await process_frame;quit(0 if ok else 1)
