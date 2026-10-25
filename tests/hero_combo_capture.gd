extends SceneTree
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(960,650);root.content_scale_size=root.size;Engine.max_fps=60;Engine.max_physics_steps_per_frame=1
 var background=ColorRect.new();background.color=Color("18262c");background.size=Vector2(960,650);root.add_child(background)
 var rig=load("res://tests/hero_combo_gait.gd").new();rig.position=Vector2(220,120);rig.scale=Vector2.ONE*2;root.add_child(rig);rig.posing=true;rig.set_process(false)
 DirAccess.make_dir_recursive_absolute("res://builds/qa/combo-frames")
 var frame=0
 var events=[]
 rig.attack_index=-1;rig.motion_amount=0;rig.sampled_pose=rig.pose_transforms()
 for attack in 3:
  rig.begin_transition()
  var duration=rig.MOTION.ATTACKS[attack].duration
  var emitted=false
  for i in int(ceil(duration*60))+1:
   rig.sample_attack(attack,minf(i/60.0,duration),1.0/60)
   rig.blend_transition(1.0/60)
   if not emitted and i/60.0>=rig.MOTION.ATTACKS[attack].hit-.045:
    events.append({"frame":frame,"path":"res://assets/audio/melee_swing%d_0.wav"%(attack+1)})
    emitted=true
   await process_frame;await process_frame;await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://builds/qa/combo-frames/%04d.png"%frame);frame+=1
 rig.begin_transition();rig.attack_index=-1
 for i in 18:
  rig.sampled_pose=rig.pose_transforms();rig.blend_transition(1.0/60);rig.queue_redraw()
  await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://builds/qa/combo-frames/%04d.png"%frame);frame+=1
 print("COMBO_CAPTURE frames=",frame)
 var event_file=FileAccess.open("res://builds/qa/combo-audio.json",FileAccess.WRITE)
 event_file.store_string(JSON.stringify({"fps":60,"frames":frame,"events":events},"  "));event_file.close()
 quit()
