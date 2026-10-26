extends SceneTree
# Knight move choice: the spear-wave set at every range (7% direct pick plus the
# ordinary pool), empowered variants of ordinary moves, and the new knight sounds.
var game
var k
var checks=0
var failures=[]
func _initialize():call_deferred("run")
func verify(ok,label):
	checks+=1
	if ok:print("PASS ",label)
	else:failures.append(label);push_error(label)
func reset(distance=200.0):
	game.state="playing";game.hitstop=0;game.combat.clear();k.soul.clear_attacks();k.soul.spend();game.audio.enemy_recent.clear()
	k.end_box();k.action="";k.pending="";k.t=0;k.phase=2;k.landed=true;k.phase_shift=0;k.dismount_t=-1;k.dead=false;k.active_battle=true
	k.weapon="spear";k.position=Vector2(300,450);k.facing=1;k.idle=100;k.speech_cooldown=100;k.history=[];k.empowered=false;k.queued_empower=false;k.sets_since_wave=3
	game.player.position=Vector2(300+distance,450);game.player.velocity=Vector2.ZERO;game.player.health=100;game.player.invincible=99
func chosen():return k.pending if k.action=="switch" else k.action
func step(seconds):
	for i in int(round(seconds*120)):
		game.hitstop=0;k._physics_process(1.0/120);game.combat._physics_process(1.0/120)
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.tuning.reset();game.start_challenge(4,2);await process_frame
	k=game.boss;game.set_process(false);game.set_physics_process(false);k.set_physics_process(false);game.player.set_physics_process(false);game.combat.set_physics_process(false);game.summon.set_physics_process(false)
	seed(7071)
	for distance in [40.0,120.0,240.0,420.0]:
		var waves=0
		for i in 400:
			reset(distance);k.choose()
			if chosen()=="wave":waves+=1
		# Direct 7% plus one share of the pool; never the old zero at close range.
		verify(waves>400*.10 and waves<400*.30,"wave set can open at "+str(distance)+" px ("+str(waves)+"/400)")
	var direct=0
	for i in 600:
		reset(120);k.history=["wave"];k.choose()
		if chosen()=="wave":direct+=1
	verify(direct>600*.035 and direct<600*.11,"right after another long combo only the 7% direct pick yields a wave ("+str(direct)+"/600)")
	var repeats=0
	for i in 300:
		reset(420);k.sets_since_wave=0;k.choose()
		if chosen()=="wave":repeats+=1
	verify(repeats==0,"a wave set never follows another wave set directly")
	reset(60);k.phase=2;k.begin("advance",k.prep_for("advance"));k.empowered=true;step(k.prep_for("advance")+3*k.ADVANCE_GAP+.05)
	verify(k.fired.has("step3"),"empowered advance adds a fourth step")
	for id in ["thrust","butt_spin","kick_thrust","uppercut"]:
		reset(60);k.begin(id,k.prep_for(id));k.empowered=true;var sent=false
		for i in 300:
			step(1.0/120);sent=sent or not k.soul.soldiers.is_empty()
		verify(sent,"empowered "+id+" sends ghost soldiers")
	reset(60);k.soul.rage=2;k.soul.release_ready=true;k.queued_empower=false
	k.soul.spend_cell();k.queued_empower=true;k.begin("thrust",k.prep_for("thrust"))
	verify(k.empowered and k.soul.rage==1 and not k.queued_empower,"a queued empower is used once and leaves the second cell")
	reset(400);game.audio.enemy_history.clear()
	k.begin("lunge",k.prep_for("lunge"));step(k.prep_for("lunge")+.5)
	verify(game.audio.enemy_history.any(func(key):return key.begins_with("knight_armor_step")),"walking on foot plays armour steps")
	reset(400);game.audio.enemy_history.clear();k.soul.begin_legion();step(3.8)
	for key in ["knight_ghost_rise","knight_ghost_glide","knight_ghost_fade"]:
		verify(key in game.audio.enemy_history,"ghost regiment plays "+key)
	var mounted_seen={}
	for distance in [60.0,150.0,320.0]:
		for i in 200:
			reset(distance);k.phase=1;k.landed=false;k.soul.rage=3;k.soul.release_ready=true;k.choose();mounted_seen[chosen()]=true
	verify(mounted_seen.keys().all(func(id):return id in ["butt","rear","advance","trample","charge","halt_thrust","double_charge","uppercut"]),"mounted phase only picks physical moves "+str(mounted_seen.keys()))
	verify(mounted_seen.has("trample") and mounted_seen.has("halt_thrust") and mounted_seen.has("double_charge"),"new mounted dashes are in rotation")
	reset();k.phase=1;k.landed=false;k.take_hit(100,"player",1);verify(k.soul.rage==0,"mounted phase gathers no rage")
	reset();k.phase=1;k.landed=false;k.begin("charge",k.prep_for("charge"));verify(not k.empowered,"mounted attacks are never empowered")
	for id in ["halt_thrust","trample"]:
		reset(320);k.phase=1;k.landed=false;game.player.invincible=0;k.begin(id,k.prep_for(id));var hit=false
		for i in 360:
			step(1.0/120);hit=hit or game.player.health<100
			if k.action=="":break
		verify(hit and k.action=="","mounted "+id+" closes the gap, lands a blow and recovers")
	reset(420);k.phase=1;k.landed=false;k.begin("double_charge",k.prep_for("double_charge"));var turned=false
	for i in 600:
		step(1.0/120);turned=turned or k.action=="rein"
	verify(turned,"double charge always wheels into a return charge")
	verify(ResourceLoader.exists("res://assets/voice/ai/knight_effort_aha.wav") and ResourceLoader.exists("res://assets/voice/ai/knight_effort_kanqiang.wav"),"new knight shouts are imported")
	game.audio.stop_all();game.queue_free();await process_frame
	print("KNIGHT_SELECTION_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
