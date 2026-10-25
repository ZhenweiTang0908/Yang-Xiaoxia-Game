extends SceneTree
func _initialize():call_deferred("run")
func run():
 var rig=load("res://tests/hero_combo_gait.gd").new();root.add_child(rig);rig.set_process(false)
 var sweep=load("res://tests/blade_sweep.gd")
 var hits=[];var false_hits=0
 for attack in 3:
  var previous={};var struck=false
  var move=rig.MOTION.ATTACKS[attack]
  for i in int(ceil(move.duration*120))+1:
   var t=i/120.0;rig.sample_attack(attack,t,1.0/120)
   var current={"base":rig.sampled_pose[7]*Vector2(74,149),"tip":rig.sampled_pose[7]*Vector2(120,168)}
   if not previous.is_empty() and t>=move.hit-.04 and t<=move.hit+.045:
    if not struck and sweep.circle_hit(previous,current,Vector2(134,135),18):hits.append({"attack":attack,"time":t});struck=true
    if sweep.circle_hit(previous,current,Vector2(500,135),18):false_hits+=1
   previous=current
 print("COMBO_TARGET hits=",hits," far_false_hits=",false_hits)
 rig.queue_free();await process_frame;quit(0 if hits.size()==3 and false_hits==0 else 1)
