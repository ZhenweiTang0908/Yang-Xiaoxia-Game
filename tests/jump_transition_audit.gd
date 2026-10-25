extends SceneTree
func _initialize():call_deferred("run")
func run():
 var rig=load("res://tests/hero_running_gait.gd").new();root.add_child(rig)
 var timeline=load("res://tests/jump_timeline.gd").new(rig)
 var peak=0.0;var errors=0;var joint_error=0.0
 for i in 313:
  timeline.advance_to(i/120.0)
  peak=maxf(peak,-timeline.height*rig.game_scale)
  if timeline.height<0 and (rig.planted[0]!=null or rig.planted[1]!=null):errors+=1
  for leg in 2:
   var thigh=1+leg*2;var calf=thigh+1;var foot=5+leg;var p=rig.sampled_pose
   joint_error=maxf(joint_error,(p[thigh]*rig.joints[calf]).distance_to(p[calf]*rig.joints[calf]))
   joint_error=maxf(joint_error,(p[calf]*rig.joints[foot]).distance_to(p[foot]*rig.joints[foot]))
 if absf(peak-520.0*520/(2*1080))>.02 or joint_error>.001 or timeline.height!=0:errors+=1
 print("JUMP_TRANSITION peak=",peak," joint_error=",joint_error," airborne_lock_errors=",errors," unreachable_releases=",rig.released_unreachable)
 rig.queue_free();await process_frame;quit(errors)
