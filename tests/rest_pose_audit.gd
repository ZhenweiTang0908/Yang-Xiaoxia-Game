extends SceneTree
func _initialize():call_deferred("run")
func run():
 var rig=load("res://tests/hero_combo_gait.gd").new();root.add_child(rig);rig.set_process(false)
 rig.attack_index=-1;rig.motion_amount=0;rig.contact_enabled=true
 var pose=rig.pose_transforms();var error=0.0
 for index in [1,2,3,4,5,6]:
  error=maxf(error,absf(pose[index].get_rotation()))
  # Measure displacement at the visible leg, not the transform's distant
  # origin: rotation about a pivot cancels most origin translation.
  for point in [rig.joints[index],Vector2(96,175),Vector2(100,199)]:
   error=maxf(error,(pose[index]*point).distance_to(point))
 for leg in 2:
  error=maxf(error,absf((pose[5+leg]*rig.joints[5+leg]).y+rig.soles[leg]-199))
 print("REST_POSE rest_geometry_or_ground_error=",error)
 rig.queue_free();await process_frame;quit(0 if error<.001 else 1)
