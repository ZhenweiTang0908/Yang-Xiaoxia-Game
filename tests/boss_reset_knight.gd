extends SceneTree
var game
var failures=[]
var checks=0
func verify(ok,label):
 checks+=1
 if not ok:failures.append(label);print("FAIL ",label)
func _initialize():call_deferred("run")
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.tuning.reset();game.start_challenge(4,2);await process_frame
 game.set_physics_process(false);game.player.set_physics_process(false);game.combat.set_physics_process(false);game.summon.set_physics_process(false)
 var k=game.boss;k.set_physics_process(false)
 var moves=["thrust","counter","butt_spin","guard","wave","bow"]+k.NEW_MOVES+k.PRESSURE_MOVES+k.SPEAR.MOVES
 for id in moves:
  game.state="playing";game.hitstop=0;game.combat.clear();k.soul.clear_attacks();k.end_box();k.phase=2;k.landed=true;k.dismount_t=-1;k.dead=false;k.active_battle=true;k.idle=100;k.position=Vector2(430,450);k.facing=1
  game.player.position=Vector2(550,450);game.player.health=100;game.player.invincible=999;k.begin(id,k.prep_for(id))
  var age=0.0
  for i in 480:
   game.hitstop=0;k._physics_process(1.0/60);game.combat._physics_process(1.0/60);age+=1.0/60
   if i==70:game.player.position.x=k.position.x-90
   if k.action=="":break
  verify(k.shown_moves.has(id),"current knight move "+id)
  verify(is_finite(k.position.x) and is_finite(k.position.y),"finite pose "+id)
 verify(k.visual.reset_art.clips.turn.size()>=8,"authored turn frames")
 verify(k.visual.reset_art.clips.advance.size()>=6,"authored advance frames")
 verify(k.visual.reset_art.clips.load.size()>=6,"authored loading frames")
 verify(k.visual.reset_art.clips.recover.size()>=8,"authored recovery frames")
 game.audio.stop_all();game.queue_free();await process_frame
 print("BOSS_RESET_KNIGHT_RESULT checks=",checks," failures=",failures);quit(0 if failures.is_empty() else 1)
