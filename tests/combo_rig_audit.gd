extends SceneTree
func _initialize():call_deferred("run")
func run():
 var rig=load("res://tests/hero_combo_gait.gd").new();root.add_child(rig);rig.set_process(false)
 var max_error=0.0;var samples=0;var exits=0
 for attack in 3:
  var duration=rig.MOTION.ATTACKS[attack].duration
  for i in 61:
   rig.sample_attack(attack,duration*i/60.0,duration/60.0)
   var p=rig.sampled_pose
   max_error=maxf(max_error,(p[9]*Vector2(64,125)).distance_to(p[7]*Vector2(64,125)))
   var a=p[7]*Vector2(74,149);var b=p[7]*Vector2(120,168)
   max_error=maxf(max_error,absf(a.distance_to(b)-Vector2(46,19).length()))
   samples+=1
  rig.sample_attack(attack,duration+.1,.1)
  if rig.blade_history.is_empty():exits+=1
 print("COMBO_RIG samples=",samples," rigid_error=",max_error," trails_expired=",exits)
 rig.queue_free();await process_frame;quit(0 if max_error<.001 and exits==3 else 1)
