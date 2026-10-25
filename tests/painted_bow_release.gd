extends SceneTree
const MOTION=preload("res://scripts/animation/hero_motion.gd")
var failures=[]
func _initialize():call_deferred("run")
func check(ok,label):
 print("PASS " if ok else "FAIL ",label)
 if not ok:failures.append(label)
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
 for enemy in game.enemies:enemy.set_physics_process(false);enemy.dead=true
 var player=game.player;player.has_bow=true;player.position=Vector2(300,450);player.velocity=Vector2.ZERO
 game.combat.clear();player.enqueue("bow")
 var release_time=-1.0;var visual_synced=false;var hidden_before=true
 for frame in 24:
  await physics_frame
  var elapsed=MOTION.BOW_DURATION-player.bow_anim
  var rig=player.skeletal_visual.painted_motion.rig
  if elapsed<MOTION.BOW_RELEASE:hidden_before=hidden_before and rig.action_state=="bow" and not rig.weapon_visible and game.combat.shots.is_empty()
  if release_time<0 and not game.combat.shots.is_empty():
   release_time=elapsed
   visual_synced=rig.action_state=="bow" and MOTION.bow_released(rig.action_elapsed)
 check(hidden_before,"draw phase hides the sword and cannot fire before release")
 check(release_time>=MOTION.BOW_RELEASE and release_time<=MOTION.BOW_RELEASE+1.0/60+.001,"arrow spawns on the first physics frame at the shared release boundary")
 check(visual_synced,"bowstring release and projectile spawn occur in the same visual phase")
 game.audio.stop_all();game.queue_free();await process_frame
 print("PAINTED_BOW_RELEASE failures=",failures," release_time=",release_time)
 quit(0 if failures.is_empty() else 1)
