extends SceneTree
func _initialize():call_deferred("run")
func run():
 var rig=load("res://tests/hero_combo_gait.gd").new();root.add_child(rig);rig.set_process(false)
 var error=0.0;var completed=0
 for fps in [30,60,120]:
  rig.attack_index=-1;rig.motion_amount=1;rig.sampled_pose=rig.pose_transforms()
  for attack in 3:
   rig.begin_transition()
   for frame in range(1,int(fps*.2)+1):
    rig.sample_attack(attack,float(frame)/fps,1.0/fps)
    rig.blend_transition(1.0/fps)
    var p=rig.sampled_pose
    for joint in [[9,0,Vector2(68,108)],[7,9,Vector2(64,125)],[10,0,Vector2(122,108)],[8,10,Vector2(124,127)]]:
     error=maxf(error,(p[joint[0]]*joint[2]).distance_to(p[joint[1]]*joint[2]))
    error=maxf(error,absf((p[7]*Vector2(74,149)).distance_to(p[7]*Vector2(120,168))-Vector2(46,19).length()))
   if rig.transition_pose.is_empty():completed+=1
 print("UPPER_BODY_TRANSITION joint_or_blade_error=",error," completed=",completed)
 rig.queue_free();await process_frame
 quit(0 if error<.001 and completed==9 else 1)
