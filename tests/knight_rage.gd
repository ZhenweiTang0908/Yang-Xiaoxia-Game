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
func reset():
	game.state="playing";game.hitstop=0;game.audio.stop_all();game.combat.clear();game.summon.reset(true)
	k.end_box();k.soul.clear_attacks();k.soul.rage=0;k.soul.release_ready=false;k.empowered=false;k.phase=2;k.max_hp=2400;k.hp=2400;k.dead=false;k.dismount_t=-1;k.phase_shift=0;k.active_battle=true;k.action="";k.position=Vector2(250,450);k.facing=1;k.weapon="spear";k.idle=100;k.speech_cooldown=100
	game.player.position=Vector2(650,450);game.player.velocity=Vector2.ZERO;game.player.health=100;game.player.invincible=0;game.player.soul_slow=0;game.player.roll_guard=0
func step(seconds):
	for i in int(round(seconds*120)):
		game.hitstop=0;game.player.invincible=maxf(0,game.player.invincible-1.0/120);game.player.soul_slow=maxf(0,game.player.soul_slow-1.0/120)
		game.combat._physics_process(1.0/120);k._physics_process(1.0/120)
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false);game.progress.journey_mode="standard";await process_frame
	game.start_challenge(4,2);await process_frame;k=game.boss;verify(is_equal_approx(k.cfg("knight_damage_scale"),0.9),"knight attacks use the 0.9 damage multiplier");verify(is_equal_approx(k.cfg("knight_hit_seal"),2.0),"bow hits default to a 2-second gourd seal");k.set_physics_process(false);game.player.set_physics_process(false);game.combat.set_physics_process(false);game.summon.set_physics_process(false);game.tuning.reset();game.tuning.values.knight_rage_release=100
	reset();k.take_hit(72,"player",1,false,false,false)
	verify(is_equal_approx(k.soul.rage,.75),"three percent HP loss fills three quarters of a rage cell")
	k.take_hit(24,"player",1,false,false,false)
	verify(is_equal_approx(k.soul.rage,1),"four percent HP loss fills one complete rage cell")
	k.begin("guard",.7);verify(k.soul.rage==1 and not k.empowered,"guard does not waste an offensive rage charge")
	k.begin("switch",.5,false);verify(k.soul.rage==1,"weapon swap does not waste rage")
	k.begin("bow",k.prep_for("bow"));verify(k.empowered and k.soul.rage==0,"next actual offensive action consumes exactly one cell")
	var times=k.bow_times("bow");verify(times.size()==6,"empowered precision bow is a six-shot string")
	step(times[0]+.025)
	var physical=game.combat.shots.filter(func(shot):return shot.kind=="knight_arrow")
	verify(physical.size()==1 and physical[0].empowered and is_equal_approx(physical[0].v.length(),1100) and physical[0].radius==19,"empowered arrow is luminous, fast and physically thicker")
	verify(k.soul.echoes.size()==1,"a physical bow release summons an upper-body soul archer")
	step(.7)
	verify(k.soul.rage==0 and k.soul.empowered_count==1,"later shots do not consume extra rage cells")
	verify(game.combat.shots.any(func(shot):return shot.kind=="soul_eagle"),"empowered soul archer releases an eagle-shaped spirit projectile")
	reset();k.soul.absorb(10000);verify(k.soul.rage==3,"rage storage is capped at three cells")
	k.soul.rage=1
	k.begin("wave",k.WAVE_PREP)
	verify(k.wave_times.size()==5,"rage transforms three spear waves into five")
	var gaps=[]
	for i in range(1,5):gaps.append(k.wave_times[i]-k.wave_times[i-1])
	verify(gaps.min()>=1.0 and gaps.max()-gaps.min()>.4,"five waves use uneven timing while preserving separate jump windows")
	game.player.position.y=330;step(k.wave_times[-1]+.12)
	verify(k.fired.has("wave4") and game.player.health==100,"all five waves execute and remain jumpable")
	reset();k.soul.rage=1;k.soul.release_ready=true;k.begin("triple_dash",k.prep_for("triple_dash"))
	var pursuit=k.pursuit_times();verify(pursuit.size()==5,"rage transforms three pursuit lunges into five")
	verify(not is_equal_approx(pursuit[1]-pursuit[0],pursuit[2]-pursuit[1]),"enhanced pursuit has deliberately varied inter-strike timing")
	step(pursuit[0]+.03)
	verify(k.soul.soldiers.size()==2,"empowered spear attack queues two delayed one-strike phantoms")
	step(.61)
	verify(game.combat.shots.any(func(shot):return shot.kind=="soul_soldier"),"queued blade/spear phantoms become real attack projectiles")
	reset();k.begin("bow",k.prep_for("bow"));var ordinary=k.bow_times("bow");step(ordinary[-1]+.05)
	verify(k.fired.keys().filter(func(key):return str(key).begins_with("arrow")).size()==4,"ordinary bow now releases four arrows per equip")
	verify(k.soul.echoes.size()<=3,"archer echoes are bounded to keep the screen readable")
	reset();k.begin("bow_double",k.prep_for("bow_double"));verify(k.bow_times("bow_double").size()==5,"ordinary mobile bow releases five shots")
	reset();k.begin("bow_volley",k.prep_for("bow_volley"));verify(k.bow_times("bow_volley").size()==3,"ordinary fan volley has three separate release waves")
	reset()
	var shot=game.combat.fire(game.player.position-Vector2(30,21),Vector2(600,0),k.soul.ARROW_DAMAGE,"enemy","soul_arrow",{"owner":k.get_instance_id()});shot.slow=1.4;shot.attack_sound="knight:soul_arrow"
	step(.08)
	verify(is_equal_approx(game.player.health,100-k.soul.ARROW_DAMAGE) and game.player.soul_slow>1.3 and game.summon.is_sealed() and game.summon.sealed==2,"real soul-arrow impact slows and briefly seals an absent ally")
	reset();game.player.invincible=2
	shot=game.combat.fire(game.player.position-Vector2(30,21),Vector2(600,0),k.soul.ARROW_DAMAGE,"enemy","soul_arrow",{"owner":k.get_instance_id()});shot.slow=1.4
	step(.08);verify(game.player.health==100 and game.player.soul_slow==0,"dodging a soul arrow also dodges its debuff")
	reset();k.soul.rage=1;k.soul.release_ready=true;k.begin("lunge",k.prep_for("lunge"));var strong=k.span(12,142,40,16)
	verify(strong.size.x>160 and k.visual!=null,"empowered spear has a longer actual attack span")
	step(1.55)
	verify(not k.empowered,"the empowered state ends with its committed attack")
	k.soul.queue_echo();k.soul.queue_soldiers();k.hp=1;k.take_hit(99,"player",1)
	verify(k.soul.echoes.is_empty() and k.soul.soldiers.is_empty() and game.combat.shots.is_empty(),"death cancels phantoms, delayed soul arrows and live projectiles")
	game.audio.stop_all();game.queue_free();await process_frame
	print("KNIGHT_RAGE checks=",checks," failures=",failures);quit(0 if failures.is_empty() else 1)
