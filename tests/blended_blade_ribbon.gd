extends SceneTree
func _initialize():call_deferred("run")
func run():
 var rig=load("res://scripts/animation/painted_rig/combo.gd").new();root.add_child(rig);rig.set_process(false)
 var worst=0.0
 for attack in 3:
  rig.attack_index=-1;rig.motion_amount=1;rig.age=.17;rig.sampled_pose=rig.pose_transforms();rig.begin_transition();rig.blade_history.clear()
  rig.sample_attack(attack,rig.MOTION.ATTACKS[attack].hit,1.0/60)
  rig.blend_transition(1.0/60)
  var tip=rig.sampled_pose[7]*Vector2(120,168)
  worst=maxf(worst,tip.distance_to(rig.blade_history.back().tip))
 print("BLENDED_RIBBON tip_error=",worst)
 rig.queue_free();await process_frame;quit(0 if worst<.001 else 1)
