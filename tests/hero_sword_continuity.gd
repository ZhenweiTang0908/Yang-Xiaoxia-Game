extends SceneTree
var failures=[]
var checks=0
func _initialize():call_deferred("run")
func verify(ok,label):
 checks+=1
 if ok:print("PASS ",label)
 else:failures.append(label);push_error(label)
func run():
 var rig=load("res://scripts/animation/painted_rig/combo.gd").new();root.add_child(rig);rig.set_process(false);rig.grounded_override=true;rig.contact_enabled=false
 for index in 3:
  var move=rig.MOTION.ATTACKS[index];var previous=Vector2.INF;var peak=0.0;var error=0.0
  for i in int(move.duration*1000)+1:
   rig.sample_attack(index,float(i)/1000,0)
   var pose=rig.sampled_pose;var tip=rig.weapon_transform(pose)*Vector2(120,168)
   if previous.is_finite():peak=maxf(peak,tip.distance_to(previous))
   previous=tip
   error=maxf(error,(pose[9]*Vector2(64,125)).distance_to(pose[7]*Vector2(64,125)))
   error=maxf(error,absf((pose[7]*Vector2(120,168)).distance_to(pose[7]*Vector2(74,149))-Vector2(46,19).length()))
  var fine_peak=0.0;previous=Vector2.INF
  for i in int(move.duration*2000)+1:
   rig.sample_attack(index,float(i)/2000,0)
   var tip=rig.weapon_transform(rig.sampled_pose)*Vector2(120,168)
   if previous.is_finite():fine_peak=maxf(fine_peak,tip.distance_to(previous))
   previous=tip
  verify(fine_peak<peak*.6 and peak<5,"slash "+str(index+1)+" has continuous motion at half-millisecond resolution")
  var pose=rig.sampled_pose;var sword=rig.weapon_transform(pose)
  verify((sword*Vector2(74,149)).distance_to(pose[7]*Vector2(74,149))<.001,"slash "+str(index+1)+" wrist keeps the sword attached to the hand")
  verify(error<.001,"slash "+str(index+1)+" keeps elbow connected and sword rigid")
 rig.queue_free()
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.start_new(false);await process_frame
 game.set_process(false);game.set_physics_process(false);game.player.set_physics_process(false)
 for e in game.enemies:e.set_physics_process(false)
 var p=game.player;p.position=Vector2(500,450);p.combo=2;p.attack_elapsed=.18;p.attack_duration=.41;p.attack_hit=true
 game.state="settings";game.hud.canvas.queue_redraw();await process_frame;await process_frame
 var actions=game.hud.buttons.map(func(b):return b.action)
 verify("hero_modern" in actions and "hero_legacy" in actions,"settings clearly expose both visual versions")
 game.hud.action("hero_legacy")
 verify(not game.use_skeletal and not game.progress.hero_mesh and not p.skeletal_visual.visible and p.art.visible,"old 2D mode takes effect immediately in settings")
 verify(p.combo==2 and p.attack_elapsed==.18 and p.attack_hit,"visual switch preserves current combat state")
 game.hud.action("hero_modern")
 var motion=p.skeletal_visual.painted_motion
 verify(game.use_skeletal and game.progress.hero_mesh and p.skeletal_visual.visible and not p.art.visible,"modern mode restores without a restart")
 verify(motion.rig.attack_index==1 and motion.rig.attack_elapsed==.18,"paused modern preview uses the current attack rather than a stale pose")
 game.state="paused";game.hud.canvas.queue_redraw();await process_frame;await process_frame
 verify(game.hud.buttons.any(func(b):return b.action=="hero_animation") and game.hud.buttons[0].action=="resume","pause menu exposes the switch while keeping resume as the default")
 game.hud.action("hero_animation");verify(not game.use_skeletal and game.state=="paused","quick switch keeps the fight paused")
 var path="/private/tmp/hero-animation-preference-test.json"
 verify(game.SAVE.write_save(game.progress,path) and game.SAVE.read_save(path).hero_mesh==false,"legacy selection survives a real save round trip")
 for suffix in ["",game.SAVE.TEMP_SUFFIX,game.SAVE.BACKUP_SUFFIX]:
  if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)
 game.audio.stop_all();game.queue_free();await process_frame;await process_frame;await create_timer(.2).timeout
 print("HERO_SWORD_CONTINUITY checks=",checks," failures=",failures);quit(0 if failures.is_empty() else 1)
