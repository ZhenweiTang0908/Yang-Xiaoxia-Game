extends SceneTree
var game
var checks=0
var failures=[]
func verify(ok,label):
 checks+=1
 if not ok:failures.append(label);print("FAIL ",label)
func _initialize():call_deferred("run")
func tick(b,seconds):
 for i in ceili(seconds*60):
  game.hitstop=0;game.player.invincible=10;b._physics_process(1.0/60)
func run():
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.tuning.reset();game.set_physics_process(false)
 var turn=preload("res://scripts/combat/combo_turn.gd").new()
 for probability in [.25,.40,.65]:
  var accepted=0
  for i in 1000:
   turn.begin(probability,float(i)/1000)
   if turn.request(Vector2.ZERO,Vector2(-40,0),1,.25):accepted+=1
   turn.advance(1)
   verify(not turn.request(Vector2.ZERO,Vector2(40,0),-1,.25),"at most one turn per combo")
  verify(accepted==int(probability*1000),"turn probability "+str(probability))
 for stage in [1,2,3]:
  game.jump_to_stage(stage);await process_frame
  var b=game.boss;b.set_physics_process(false);game.player.set_physics_process(false);game.combat.set_physics_process(false);game.summon.set_physics_process(false)
  b.active_battle=true;b.position=Vector2(660,450);game.player.position=Vector2(400,450);b.facing=-1
  verify(b.has_method("clear_attacks"),"reset route "+str(stage))
  for i in b.spec.moves.size():
   game.state="playing";b.hp=b.max_hp;b.phase=1;b.phase_shift=0;b.clear_attacks();b.cooldown=99;game.player.health=100;game.player.invincible=0;b.start_move(i)
   var expected_id=b.move.id
   var health=game.player.health
   for f in maxi(1,int(b.windup*60)-2):game.hitstop=0;b._physics_process(1.0/60)
   verify(game.player.health==health,"no damage in windup "+b.move.id)
   tick(b,4)
   verify(b.shown_moves.has(b.move.id),"move selected "+b.move.id)
   verify(b.audio_stages.any(func(e):return e.move==expected_id and e.stage=="release"),"release cue "+b.move.id)
   b.clear_attacks();verify(b.effects.is_empty() and b.events.is_empty(),"clear all owned geometry "+b.move.id)
  if stage==3:
   b.hp=b.max_hp/3;b.phase=2;b.phase_shift=0;b.cooldown=99;game.audio.voice_player.stop()
   verify(b.desired_phase()==3,"one third threshold inclusive")
   b._physics_process(1.0/60);verify(b.phase==3,"moon transformation starts")
   game.audio.voice_player.stop();tick(b,3)
   b.cooldown=99;b.clear_attacks();b.phase=3;b.moon_clock=0
   var x=game.player.position.x;b._physics_process(1.0/60)
   verify(b.effects.any(func(e):return e.type=="moon_column"),"independent moonfall")
   var column=b.effects.filter(func(e):return e.type=="moon_column")
   if not column.is_empty():
    game.player.position.x+=100;tick(b,.2);verify(column[0].p.x==x,"moon locks once, no tracking")
   b.clear_attacks();game.player.health=100;game.player.invincible=0;game.player.position=Vector2(400,450)
   b.add_effect("moon_column",Vector2(400,130),Vector2.ZERO,18,b.cfg("moon_core"),b.cfg("moon_warning"),Vector2(46,320))
   b.advance_effects(.59);verify(game.player.health==100,"faint moonlight is harmless")
   b.advance_effects(.02);verify(game.player.health<100,"bright core deals damage")
   var hit_health=game.player.health;game.player.invincible=0;b.advance_effects(.03);verify(game.player.health==hit_health,"one column hits once")
   b.advance_effects(.15);game.player.invincible=0;b.advance_effects(.05);verify(game.player.health==hit_health,"afterglow is harmless")
   b.phase_shift=0;b.hp=1;b.take_hit(10,"brother",1)
   verify(game.state=="boss_cinematic" and not b.defeat_complete,"lethal enters recall before reward")
   var age=b.recall_age;game.state="paused";b._physics_process(1);verify(b.recall_age==age,"pause freezes cinematic")
   game.cinematic_resume=true;game.resume_battle();verify(game.state=="boss_cinematic","resume returns cinematic")
   tick(b,6);verify(not b.defeat_complete,"no early settlement")
   tick(b,.5);verify(b.defeat_complete and game.state=="playing","recall completes before victory")
   var kills=game.kills;tick(b,.5);verify(game.kills==kills,"settle exactly once")
 game.jump_to_stage(1);await process_frame
 var stone=game.boss;stone.set_physics_process(false);stone.active_battle=true
 stone.add_effect("boulder",Vector2(400,430),Vector2.ZERO,18,2)
 verify(stone.break_rocks(Rect2(380,410,40,40),18),"real rocks can be broken")
 stone.advance_effects(.01);verify(stone.effects.is_empty(),"broken rock cannot keep hurting")
 game.jump_to_stage(4);await process_frame
 var knight=game.boss;knight.set_physics_process(false);knight.enter_foot_challenge();knight.active_battle=true;knight.facing=1;game.player.position.x=knight.position.x-100
 knight.begin("thrust",knight.prep_for("thrust"));knight.reset_turn.begin(1,0);knight.t=knight.prep_for("thrust")+.2;knight.face_target()
 verify(knight.reset_turn.remaining>0,"knight eligible segment starts deliberate turn")
 game.hitstop=0;game.state="playing";var action_time=knight.t;knight._physics_process(.05)
 verify(knight.t==action_time,"turn freezes knight action clock")
 game.audio.stop_all();game.queue_free();await process_frame
 print("BOSS_RESET_BEHAVIOR_RESULT checks=",checks," failures=",failures)
 quit(0 if failures.is_empty() else 1)
