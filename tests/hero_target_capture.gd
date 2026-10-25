extends SceneTree
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(960,650);root.content_scale_size=root.size;Engine.max_fps=60;Engine.max_physics_steps_per_frame=1
 var background=ColorRect.new();background.color=Color("18262c");background.size=Vector2(960,650);root.add_child(background)
 var rig=load("res://tests/hero_combo_gait.gd").new();rig.position=Vector2(220,120);rig.scale=Vector2.ONE*2;root.add_child(rig);rig.posing=true;rig.set_process(false)
 var target=load("res://tests/practice_target.gd").new();target.position=rig.position+Vector2(134,135)*2;target.scale=Vector2.ONE*2;root.add_child(target)
 var sweep=load("res://tests/blade_sweep.gd")
 DirAccess.make_dir_recursive_absolute("res://builds/qa/target-frames")
 var frame=0
 var events=[]
 for attack in 3:
  var duration=rig.MOTION.ATTACKS[attack].duration
  var emitted=false
  var previous={};var struck=false
  for i in int(ceil(duration*60))+1:
   target.step(1.0/60)
   rig.sample_attack(attack,minf(i/60.0,duration),1.0/60)
   var current={"base":rig.sampled_pose[7]*Vector2(74,149),"tip":rig.sampled_pose[7]*Vector2(120,168)}
   var hit=rig.MOTION.ATTACKS[attack].hit
   if not struck and not previous.is_empty() and i/60.0>=hit-.04 and i/60.0<=hit+.045 and sweep.circle_hit(previous,current,Vector2(134,135),18):
    target.strike(24+attack*6);struck=true
    events.append({"frame":frame,"path":"res://assets/audio/melee_stone%d_0.wav"%(attack+1)})
   previous=current
   if not emitted and i/60.0>=rig.MOTION.ATTACKS[attack].hit-.045:
    events.append({"frame":frame,"path":"res://assets/audio/melee_swing%d_0.wav"%(attack+1)})
    emitted=true
   await process_frame;await process_frame;await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://builds/qa/target-frames/%04d.png"%frame);frame+=1
 print("TARGET_CAPTURE frames=",frame," hits=",target.hits," health=",target.health)
 var event_file=FileAccess.open("res://builds/qa/target-audio.json",FileAccess.WRITE)
 event_file.store_string(JSON.stringify({"fps":60,"frames":frame,"events":events},"  "));event_file.close()
 quit()
