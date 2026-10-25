extends SceneTree
var failures=0
var reference={}
func _initialize():call_deferred("run")
func run():
 for fps in [120,60,30]:await audit(fps)
 quit(failures)
func audit(fps):
 var rig=load("res://tests/hero_running_gait.gd").new();root.add_child(rig);rig.set_process(false);rig.contact_enabled=true
 var timeline=load("res://tests/locomotion_timeline.gd").new(rig)
 var max_drift=0.0;var joint_error=0.0;var samples=0
 var cadence_error=0.0
 for i in fps*3:
  var previous_releases=rig.released_unreachable
  timeline.advance_to(float(i)/fps)
  var transforms=rig.sampled_pose
  if fps==120:reference[timeline.tick]=transforms.duplicate()
  else:
   for part in transforms.size():
    var expected=reference[timeline.tick][part]
    cadence_error=maxf(cadence_error,transforms[part].origin.distance_to(expected.origin))
    cadence_error=maxf(cadence_error,absf(transforms[part].get_rotation()-expected.get_rotation()))
  if rig.released_unreachable>previous_releases:print("UNREACHABLE at=",rig.age," amount=",rig.motion_amount)
  for leg in 2:
   if rig.planted[leg]==null:continue
   samples+=1
   var foot=5+leg;var thigh=1+leg*2;var calf=thigh+1
   var actual=(transforms[foot]*rig.joints[foot]).x*rig.game_scale+rig.travel_x
   max_drift=maxf(max_drift,absf(actual-rig.planted[leg]))
   joint_error=maxf(joint_error,(transforms[thigh]*rig.joints[calf]).distance_to(transforms[calf]*rig.joints[calf]))
 print("CONTACT_TRANSITION fps=",fps," samples=",samples," max_world_error=",max_drift," joint_error=",joint_error," unreachable_releases=",rig.released_unreachable," pelvis_correction=",rig.max_pelvis_correction," cadence_error=",cadence_error)
 if max_drift>.001 or joint_error>.001 or rig.released_unreachable>0 or cadence_error>.001:failures+=1
 rig.queue_free();await process_frame
