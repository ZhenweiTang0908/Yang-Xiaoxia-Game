extends SceneTree
var game
var k
var checks=0
var failures=[]
func _initialize():call_deferred("run")
func verify(ok,label):
 checks+=1
 if not ok:failures.append(label);push_error("FAIL "+label)
func reset():
 game.state="playing";game.hitstop=0;game.combat.clear();game.summon.reset(true);k.soul.clear_attacks();k.soul.spend();k.soul.last_echo=-100
 game.player.position=Vector2(700,450);game.player.velocity=Vector2.ZERO;game.player.health=100;game.player.invincible=0;game.player.roll_guard=0
 k.action="";k.phase=2;k.active_battle=true;k.dead=false;k.dismount_t=-1;k.phase_shift=0;k.position=Vector2(250,450);k.weapon="bow";k.speech_cooldown=100;k.time+=1
func actual_hit(shot,expected):
 game.combat.shots=[shot];shot.p=game.player.position-Vector2(20,21);shot.v=Vector2(shot.v.length(),0)
 game.combat._physics_process(.05)
 verify(is_equal_approx(game.player.health,100-expected),"actual arrow hit removes "+str(expected)+" health")
 verify(game.summon.is_sealed() and is_equal_approx(game.summon.sealed,2),"actual arrow hit seals absent ally for two seconds")
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.tuning.reset();game.start_challenge(4,2);await process_frame
 k=game.boss;game.set_process(false);game.set_physics_process(false);game.player.set_physics_process(false);k.set_physics_process(false);game.combat.set_physics_process(false);game.summon.set_physics_process(false)
 for strong in [false,true]:
  for id in ["bow","bow_double","bow_volley"]:
   reset();k.begin(id,k.prep_for(id));k.empowered=strong;k.t=k.bow_times(id)[0];k.run_bow(0,id)
   var shots=game.combat.shots.filter(func(s):return s.kind=="knight_arrow")
   if shots.is_empty():verify(false,"knight released real arrows");quit(1);return
   verify(shots.all(func(s):return s.damage==(9 if strong else 6)),id+" uses exact specified damage")
   verify(shots.all(func(s):return is_equal_approx(s.v.length(),1100 if strong else 780)),id+" restores old speed")
   actual_hit(shots[0],9 if strong else 6)
  reset();k.empowered=strong;k.soul.queue_echo();k.soul.advance(.7)
  var ghosts=game.combat.shots.filter(func(s):return s.kind in ["soul_arrow","soul_eagle"])
  if ghosts.is_empty():verify(false,"echo released a real arrow");quit(1);return
  verify(ghosts[0].damage==(7 if strong else 5),"ghost echo uses exact specified damage")
  verify(is_equal_approx(ghosts[0].v.length(),608 if strong else 488),"ghost echo keeps existing projectile speed")
  actual_hit(ghosts[0],7 if strong else 5)
  reset();k.empowered=strong;k.soul.begin_legion();k.soul.advance_legion(1.4)
  var arrows=game.combat.shots.filter(func(s):return s.kind in ["soul_arrow","soul_eagle"])
  verify(arrows.size()==3 and arrows.all(func(s):return s.damage==(7 if strong else 5)),"all three summoned archers use the matching arrow damage")
 reset();game.summon.request();game.summon.brother.set_physics_process(false);game.summon.phase="active";game.summon.remaining=30
 game.summon.arrow_hit();verify(game.summon.phase=="active" and game.summon.remaining==22,"present ally still loses eight seconds rather than being sealed")
 reset();game.summon.seal(10);game.summon.arrow_hit();verify(game.summon.sealed==10,"arrow cannot shorten the dismount seal")
 game.audio.stop_all();game.queue_free();await process_frame;await process_frame
 print("KNIGHT_ARROW_BALANCE_RESULT checks=",checks," failures=",failures);quit(0 if failures.is_empty() else 1)
