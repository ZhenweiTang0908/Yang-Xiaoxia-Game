extends SceneTree
func _initialize():call_deferred("run")
func run():
 var rig=load("res://scripts/animation/painted_rig/combo.gd").new();root.add_child(rig);rig.set_process(false)
 var error=0.0;var foot_error=0.0
 for fps in [30,60,120]:
  rig.attack_index=-1;rig.motion_amount=1;rig.contact_enabled=true;rig.age=.11
  rig.sampled_pose=rig.pose_transforms();rig.begin_transition()
  for i in range(1,int(fps*.12)):
   rig.motion_amount=0;rig.landing_squash=5*sin(PI*float(i)/fps/.18)
   rig.sampled_pose=rig.pose_transforms();var destination=rig.sampled_pose.duplicate();rig.blend_transition(1.0/fps)
   for foot in [5,6]:foot_error=maxf(foot_error,(destination[foot]*rig.joints[foot]).distance_to(rig.sampled_pose[foot]*rig.joints[foot]))
   for index in [1,3]:error=maxf(error,(rig.sampled_pose[0]*rig.joints[index]).distance_to(rig.sampled_pose[index]*rig.joints[index]))
 for attack in 3:
  rig.attack_index=attack
  for frame in 60:
   rig.attack_elapsed=float(frame)/120;rig.landing_squash=0
   var pose=rig.pose_transforms()
   for index in [1,3]:error=maxf(error,(pose[0]*rig.joints[index]).distance_to(pose[index]*rig.joints[index]))
 print("TRANSITION_HIP error=",error," foot_error=",foot_error)
 rig.queue_free();await process_frame;quit(0 if error<.001 and foot_error<.001 else 1)
