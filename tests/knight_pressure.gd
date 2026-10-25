extends SceneTree
var game
var k
var failures=[]
var checks=0
func _initialize():call_deferred("run")
func verify(ok,label):
	checks+=1
	if ok:print("PASS ",label)
	else:failures.append(label);push_error(label)
func reset(id,x=650.0,y=450.0):
	game.combat.clear();game.state="playing";game.hitstop=0;game.summon.reset(true)
	game.player.position=Vector2(x,y);game.player.velocity=Vector2.ZERO;game.player.health=100;game.player.invincible=0;game.player.roll_guard=0;game.player.form_transition=0
	k.soul.rage=0;k.soul.clear_attacks();k.empowered=false;k.end_box();k.phase=2;k.landed=true;k.dismount_t=-1;k.phase_shift=0;k.dead=false;k.hp=2400
	k.position=Vector2(250,450);k.facing=1;k.weapon=k.weapon_for(id);k.visual.held_action="";k.idle=100;k.begin(id,k.prep_for(id))
func step(seconds):
	for i in int(round(seconds*120)):
		game.hitstop=0;game.player.invincible=maxf(0,game.player.invincible-1.0/120)
		game.combat._physics_process(1.0/120);k._physics_process(1.0/120)
func freeze():
	k=game.boss;k.set_physics_process(false);k.active_battle=true;k.intro=0
	game.player.set_physics_process(false);game.combat.set_physics_process(false);game.summon.set_physics_process(false)
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true
	game.start_new(false);game.progress.journey_mode="standard";await process_frame
	var journey=game.progress.duplicate(true)
	game.start_challenge(4,2);await process_frame;freeze();game.tuning.reset()
	verify(k.phase==2 and k.hp==2400 and k.body_height==106,"direct entry starts a full-health foot duel")
	verify(game.player.health==100 and not game.summon.is_sealed() and k.dust_age<0,"direct entry has no dust damage or gourd seal")
	verify(game.tonic_count()==2 and game.progress==journey,"entry grants two moon-dew charges without changing journey")
	game.challenge_tonic=0;game.die("knight_spear");game.retry();await process_frame;await process_frame;freeze()
	verify(k.phase==2 and game.tonic_count()==2 and game.player.health==100,"foot retry reliably refills health and both moon-dew charges")
	verify(game.challenge_practice,"foot retry is recorded as practice")
	game.start_challenge();await process_frame;freeze()
	verify(k.phase==1 and game.challenge_entry_phase==1 and not game.challenge_practice,"full challenge explicitly resets to mounted phase")
	k.begin_dismount();step(1.0)
	verify(k.phase==2 and game.challenge_entry_phase==2,"natural dismount creates the foot retry checkpoint")
	verify(not game.challenge_practice,"uninterrupted two-phase challenge still earns a full victory")
	game.die();game.retry();await process_frame;await process_frame;freeze()
	verify(k.phase==2 and game.tonic_count()==2 and game.challenge_practice,"death after dismount resumes foot phase with two dew")
	var before=game.stage_record(4,"standard").get("completions",0)
	game.finish_level()
	verify(game.stage_record(4,"standard").get("completions",0)==before and game.stage_result.practice,"practice cannot inflate full-challenge records")
	game.state="playing"
	for id in k.PRESSURE_MOVES:
		reset(id)
		step(k.prep_for(id)-.025)
		verify(game.player.health==100,id+" preserves a damage-free readable windup")
		verify(k.visual.selected==k.visual.pressure or id=="triple_dash",id+" uses a painted spear/bow pose")
	reset("spin_rush",800);k.position.x=150;step(1.6)
	verify(k.position.x>700,"spinning lance closes more than 550 pixels")
	verify(is_equal_approx(game.player.health,100-23.4*1.08),"spinning lance catches a distant grounded target once")
	verify(k.hit_box==null,"spinning lance removes its travelling hitbox")
	reset("spin_rush",800);step(.57);game.player.position.x=100;step(.22)
	verify(k.facing==1,"rush cannot reverse after committing its raised-arm tell")
	reset("lunge",650);step(1.4)
	verify(k.position.x>575 and is_equal_approx(game.player.health,100-23.4*1.08),"long lunge reaches a target 400 px away")
	reset("thrust",360);step(.65)
	verify(k.position.x>260 and is_equal_approx(game.player.health,82.0),"close thrust steps in and hits in actual local range")
	reset("thrust",900);step(.65)
	verify(game.player.health==100,"local spear cannot damage an unreachable distant target")
	reset("triple_dash",600);step(1.06)
	verify(k.fired.has("drive0"),"threefold pursuit commits its first moving strike")
	game.player.position.x=220;step(.27)
	verify(k.lock_dir==-1,"second pursuit visibly reacquires the changed side")
	game.player.position.x=850;step(.26)
	verify(k.lock_dir==-1,"second pursuit respects its locked direction")
	step(1.5);verify(k.fired.has("drive2") and k.hit_box==null,"third pursuit completes and clears its final strike")
	reset("spear_return",500);step(.65)
	verify(game.combat.shots.size()==1 and k.visual.selected_frame==6,"throw visibly leaves the hand empty and creates a real spear")
	step(2.0)
	verify(is_equal_approx(game.player.health,64.0),"outbound and returning spear each hit at most once")
	verify(not k.spear_in_flight(),"thrown spear returns to the owner and disappears")
	reset("spear_return",500,370);step(2.6)
	verify(game.player.health==100,"a high jump clears both low spear passes")
	reset("bow_volley",700);step(.67)
	verify(game.combat.shots.size()==3,"ranged volley releases three different arrow lanes")
	var shots=game.combat.shots
	verify(shots[0].v.angle()<shots[1].v.angle() and shots[1].v.angle()<shots[2].v.angle(),"volley fans out rather than stacking identical arrows")
	verify(shots.all(func(shot):return is_equal_approx(shot.seal,k.cfg("knight_hit_seal")) and not shot.homing),"arrows apply the configured gourd seal without homing")
	reset("bow",650);game.player.velocity.x=330;step(.55)
	var locked=k.aim;game.player.velocity.x=-330;step(.10)
	verify(k.aim.is_equal_approx(locked),"predictive bow locks before release so direction changes remain a counterplay")
	var seen={};var far_valid=true
	for distance in [50,130,250,650]:
		for i in 80:
			reset("lunge",250+distance);k.history=[];k.choose()
			var id=k.pending if k.action=="switch" else k.action;seen[id]=true
			if distance==650:far_valid=far_valid and id not in ["thrust","butt_spin","guard","kick_thrust","spear_slam"]
	verify(far_valid,"far selection always uses a gap closer or ranged move")
	for id in k.PRESSURE_MOVES:verify(seen.has(id),id+" reachable through ordinary AI")
	verify(not seen.has("drag") and not seen.has("draw_slash") and not seen.has("cross_cut") and not k.has_method("act_drag"),"all sword actions are removed")
	reset("spear_return",700);step(.7);k.hp=1;k.take_hit(999,"player",1)
	verify(game.combat.shots.is_empty(),"death cancels outbound/returning spear")
	for key in k.DIALOGUE.LINES:
		var voice=load("res://assets/voice/knight_"+key+".wav")
		verify(voice and voice.get_length()>.5 and voice.data.size()>20000,"real Mandarin PCM exists for "+key)
	game.audio.stop_all();k.dead=false;k.speech_cooldown=0
	verify(k.speak("spin_rush") and game.subtitle.contains("破阵") and game.audio.voice_player.playing,"boss line starts real speech and matching subtitles")
	verify(not k.speak("wave"),"normal battle dialogue has a 12-second cooldown")
	game.say_line("唐牛牛在此，谁敢放肆！","niu_demon");k.speech_cooldown=0
	verify(not k.speak("bow_volley",true) and game.subtitle.begins_with("唐牛牛"),"boss dialogue cannot interrupt brother speech")
	game.audio.stop_all();game.queue_free();await process_frame
	print("KNIGHT_PRESSURE checks=",checks," failures=",failures);quit(0 if failures.is_empty() else 1)
