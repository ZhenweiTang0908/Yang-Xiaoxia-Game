extends SceneTree
# 断誓枪骑 acceptance checks: phase lock, landing dust, arena-wide spear waves,
# seal sources, gourd-seal lifecycle and the separate challenge entrance.
var failures=[]
var checks=0
var game
func _initialize():call_deferred("run")
func verify(condition,label):
	checks+=1
	if condition:print("PASS ",label)
	else:failures.append(label);push_error("FAIL "+label)
# Manual stepping clears hit stop, which otherwise only counts down on real frames.
func step(node,seconds,dt=1.0/60,keep_hitstop=false):
	var n=int(round(seconds/dt))
	for i in n:
		if not keep_hitstop:game.hitstop=0
		node._physics_process(dt)
func fresh():
	game.start_challenge();await process_frame
	var knight=game.boss;knight.set_physics_process(false);knight.active_battle=true;knight.intro=0
	game.summon.set_physics_process(false)
	for e in game.enemies:if e!=knight:e.set_physics_process(false)
	game.player.invincible=0;game.player.health=100
	return knight
func ground(p,x):
	p.position=Vector2(x,450);p.velocity=Vector2.ZERO;p.invincible=0;p.roll_guard=0;p.dash_time=0;p.form_transition=0
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true
	game.start_new(false);await process_frame
	var journey_level=game.progress.level;var journey_tonic=game.progress.tonic
	var knight=await fresh()
	verify(game.level.number==4 and game.is_challenge() and knight.spec.id=="knight","challenge loads the knight arena")
	verify(game.progress.level==journey_level and game.progress.tonic==journey_tonic,"challenge leaves journey progress untouched")
	verify(game.enemies.size()==1 and game.level.spawns.is_empty() and game.level.features.is_empty(),"only the knight: no minions or arena hazards")
	verify(game.player.has_bow and game.summon.unlocked,"challenge provides bow and gourd")
	verify(knight.phase==1 and knight.hp==2400 and knight.max_hp==2400,"mounted phase starts at 2400")
	verify(game.level.length==960 and game.camera.position.x==480,"960 px fixed arena camera")

	# --- phase lock: a huge hit cannot skip the foot phase
	knight.take_hit(5000,"player",1)
	verify(knight.dismount_t>=0 and knight.phase_shift>0 and knight.phase==1,"crossing half health starts the dismount")
	var hp=knight.hp;knight.take_hit(500,"player",1)
	verify(knight.hp==hp,"no damage while dismounting")
	knight.begin_dismount();verify(knight.dismount_t==0,"dismount restarts cleanly if re-entered")
	game.progress.journey_mode="relaxed"
	ground(game.player,200);game.player.invincible=1.0;game.player.roll_guard=.2
	game.summon.request();game.summon.phase="active";game.summon.remaining=21.0
	var before=game.player.health
	step(knight,knight.DISMOUNT_LAND+.02)
	verify(knight.phase==2 and knight.hp==2400 and knight.max_hp==2400,"foot phase restores full 2400 health")
	verify(is_equal_approx(before-game.player.health,10.0),"landing dust deals exactly 10 despite relaxed mode and invulnerability")
	verify(game.summon.is_sealed() and is_equal_approx(game.summon.sealed,10.0),"landing dust seals the gourd for 10 s")
	verify(game.summon.seal_resume.phase=="active" and is_equal_approx(game.summon.seal_resume.remaining,21.0),"active brother is stored with remaining assist time")
	var health_after=game.player.health;step(knight,.3)
	verify(game.player.health==health_after and knight.damage_log.count("dust")==1,"dust resolves once per transition")
	verify(knight.action=="" and knight.dismount_t>=0,"no attack begins while the dust settles")
	step(knight,knight.DISMOUNT_TOTAL-knight.dismount_t-.02)
	verify(knight.dismount_t>=0 and knight.action=="","pause of 1 s after the dust before choosing")
	step(knight,.1)
	verify(knight.dismount_t<0,"foot phase begins after the dismount")
	game.progress.journey_mode="standard"

	# dust lethal at 10 health
	knight=await fresh();ground(game.player,300);game.player.health=10
	knight.hp=1100;knight.begin_dismount();step(knight,knight.DISMOUNT_LAND+.02)
	verify(game.state=="dead" and game.death_source=="knight_dust","dust can finish a hero at 10 health")
	game.state="playing"

	# --- spear waves: arena-wide, ignore invulnerability, jumpable
	knight=await fresh();knight.phase=2;knight.max_hp=2400;knight.hp=2400;knight.position.x=480
	var cases=[["left edge",14.0],["right edge",946.0],["in front",560.0],["behind",400.0]]
	for c in cases:
		ground(game.player,c[1]);game.player.health=100
		knight.fire_wave()
		verify(is_equal_approx(game.player.health,78.4),"standing at "+c[0]+" takes 21.6 wave damage")
	ground(game.player,600);game.player.health=100;game.player.invincible=.23;game.player.roll_guard=.23;game.player.dash_time=.1
	knight.fire_wave();verify(is_equal_approx(game.player.health,78.4),"rolling invulnerability does not pass the wave")
	ground(game.player,600);game.player.health=100;game.player.invincible=.55;game.player.form_transition=.4
	knight.fire_wave();verify(is_equal_approx(game.player.health,78.4),"transform invulnerability does not pass the wave")
	ground(game.player,600);game.player.health=100;game.player.invincible=.8
	knight.fire_wave();verify(is_equal_approx(game.player.health,78.4),"post-hit invulnerability does not pass the wave")
	ground(game.player,600);game.player.position.y=450-13;game.player.health=100
	knight.fire_wave();verify(game.player.health==100,"feet 13 px up clear the wave")
	ground(game.player,600);game.player.position.y=450-11;game.player.health=100
	knight.fire_wave();verify(is_equal_approx(game.player.health,78.4),"feet 11 px up are still hit")
	# A light tap jump: the shortest possible hop clears the band.
	ground(game.player,600)
	var peak=0.0;var vy=-game.player.JUMP_SPEED;var y=0.0;var released=false;var airborne_above=0.0
	for i in 200:
		if not released and i>=1:released=true;vy=maxf(vy,-190)
		vy+=game.player.GRAVITY/60.0;y-=vy/60.0
		if y<=0:break
		peak=maxf(peak,y)
	verify(peak>knight.WAVE_HIGH+5,"light tap jump rises above the wave band (peak "+str(snappedf(peak,.1))+")")
	vy=-game.player.JUMP_SPEED;y=0.0
	for i in 200:
		vy+=game.player.GRAVITY/60.0;y-=vy/60.0
		if y<=0:break
		if y>knight.WAVE_HIGH:airborne_above+=1.0/60
	verify(airborne_above<game.tuning.get_value("knight_wave_late")-game.tuning.get_value("knight_wave_gap"),"one early full jump cannot cover both third-wave timings ("+str(snappedf(airborne_above,.01))+" s)")

	# wave timings and selection rules
	knight.wave_uses=0;knight.begin("wave",knight.WAVE_PREP)
	verify(knight.wave_times==[.42,1.52,2.62] and not knight.move.delayed,"first foot wave set is even: 0.42 / 1.52 / 2.62")
	knight.finish(.1);knight.begin("wave",knight.WAVE_PREP)
	verify(is_equal_approx(knight.wave_times[2],3.57) and knight.move.delayed,"second set delays the third wave to 3.57")
	knight.finish(.1)
	ground(game.player,900);knight.position.x=100;knight.facing=1;knight.weapon="spear";game.player.health=100
	knight.wave_uses=0;knight.begin("wave",knight.WAVE_PREP);knight.sets_since_wave=0
	var hits=[];var last=game.player.health;var clock=0.0
	while knight.action=="wave" and clock<4:
		game.hitstop=0;knight._physics_process(1.0/60);clock+=1.0/60
		game.player.invincible=0
		if game.player.health<last:hits.append(snappedf(clock,.01));last=game.player.health
	verify(hits.size()==3 and absf(hits[0]-.42)<.02 and absf(hits[1]-1.52)<.02 and absf(hits[2]-2.62)<.02,"three standing hits at authored times "+str(hits))
	verify(knight.action=="" and knight.idle>=.55,"wave set ends with a recovery window")
	for i in 30:
		knight.idle=0;knight.sets_since_wave=0;knight.history=["thrust"]
		knight.choose()
		if knight.action=="wave" or knight.pending=="wave":verify(false,"wave chosen right after a wave set")
		knight.action="";knight.pending=""
	verify(true,"no back-to-back wave sets over 30 choices")
	var repeats=0
	for i in 40:
		knight.history=["thrust","thrust"]
		ground(game.player,knight.position.x+knight.facing*120)
		knight.idle=0;knight.choose()
		if knight.action=="thrust" or knight.pending=="thrust":repeats+=1
		knight.action="";knight.pending=""
	verify(repeats==0,"a technique is never used three times in a row")

	# --- seal sources
	knight=await fresh();knight.phase=2;knight.weapon="bow";knight.position.x=300;knight.facing=1
	ground(game.player,700);game.summon.reset(true)
	knight.begin("bow",game.tuning.get_value("knight_bow_draw"))
	game.combat.set_physics_process(true)
	for i in 120:
		game.hitstop=0;knight._physics_process(1.0/60);game.combat._physics_process(1.0/60)
		if game.player.health<100:break
	verify(is_equal_approx(game.player.health,100-knight.ARROW_DAMAGE) and game.summon.is_sealed() and is_equal_approx(game.summon.sealed,2.0),"rapid bow arrow deals ARROW_DAMAGE (8) and seals for 2 s")
	game.summon.reset(true);ground(game.player,700);game.player.health=100;game.player.invincible=.5
	knight.begin("bow",game.tuning.get_value("knight_bow_draw"))
	for i in 120:game.hitstop=0;knight._physics_process(1.0/60);game.combat._physics_process(1.0/60)
	verify(game.player.health==100 and not game.summon.is_sealed(),"an arrow dodged by invulnerability does not seal")
	knight.weapon="spear";game.summon.reset(true);ground(game.player,knight.position.x+90);game.player.health=100
	knight.begin("spear_slam",knight.prep_for("spear_slam"))
	for i in 55:game.hitstop=0;knight._physics_process(1.0/60);game.combat._physics_process(1.0/60)
	verify(is_equal_approx(game.player.health,100-25.2*1.08) and not game.summon.is_sealed(),"heavy spear sweep deals 25.2×1.08 without a sword or gourd seal")
	game.summon.reset(true);ground(game.player,knight.position.x+90);game.player.health=100;game.player.invincible=5
	knight.begin("spear_slam",knight.prep_for("spear_slam"))
	for i in 55:game.hitstop=0;knight._physics_process(1.0/60);game.combat._physics_process(1.0/60)
	verify(game.player.health==100 and not game.summon.is_sealed(),"rolled-through heavy spear sweep does not seal")

	# --- mounted charge: only the lance tip, no tracking, one hit
	knight=await fresh();knight.position.x=800;knight.facing=-1;ground(game.player,500);game.player.health=100
	knight.begin("charge",game.tuning.get_value("knight_charge_windup"))
	var dir=knight.lock_dir
	for i in 120:
		game.hitstop=0;knight._physics_process(1.0/60);game.combat._physics_process(1.0/60);game.player.invincible=0
		if knight.fired.has("run"):game.player.position.x=500
	verify(dir==-1 and is_equal_approx(game.player.health,100-21.6*1.08),"charge locks direction and the lance tip deals 21.6×1.08 once")
	knight=await fresh();knight.position.x=800;knight.facing=-1;ground(game.player,700);game.player.health=100
	knight.begin("charge",game.tuning.get_value("knight_charge_windup"))
	for i in 20:game.hitstop=0;knight._physics_process(1.0/60)
	game.player.position.x=900
	for i in 100:game.hitstop=0;knight._physics_process(1.0/60);game.combat._physics_process(1.0/60);game.player.invincible=0
	verify(knight.lock_dir==-1 and game.player.health==100,"committed charge does not turn after the hero and the horse body is harmless")

	# --- guard halves frontal light hits and counters once; heavy hits break it
	knight=await fresh();knight.phase=2;knight.position.x=480;knight.facing=1;knight.hp=2400;knight.max_hp=2400
	knight.begin("guard",knight.GUARD_TIME);game.hitstop=0;knight._physics_process(1.0/60)
	knight.take_hit(20,"player",-1);verify(is_equal_approx(knight.hp,2390.0),"frontal hit during guard is halved")
	game.hitstop=0;knight._physics_process(1.0/60);verify(knight.action=="counter","guard triggers a counter thrust")
	knight.finish(.5);knight.begin("guard",knight.GUARD_TIME);knight.take_hit(20,"player",-1,true)
	verify(knight.action=="stagger","rising slash / blast breaks the guard")

	# --- gourd seal lifecycle
	knight=await fresh();var s=game.summon;s.set_physics_process(false)
	s.reset(true);s.seal(7);verify(s.is_sealed() and s.seal_resume.phase=="ready","ready gourd is sealed")
	verify(not s.request(),"summon is blocked while sealed")
	s.seal(3);verify(is_equal_approx(s.sealed,7.0),"repeated seal keeps the longer remaining time")
	s.seal(9);verify(is_equal_approx(s.sealed,9.0),"longer repeated seal extends to the new duration")
	step(s,.5)
	verify(s.gourd.distance_to(s.seal_ground)<1,"gourd falls to the ground near the hero")
	game.player.position.x+=200;step(s,.5)
	verify(s.gourd.distance_to(s.seal_ground)<1,"dropped gourd does not follow the hero")
	var frozen=s.sealed;game.state="paused";step(s,1.0);game.state="playing"
	verify(is_equal_approx(s.sealed,frozen),"pause freezes the seal timer")
	game.hitstop=.5;step(s,.2,1.0/60,true);verify(is_equal_approx(s.sealed,frozen),"hit stop freezes the seal timer");game.hitstop=0
	step(s,s.sealed+.01);verify(s.is_sealed() and s.seal_return>0,"seal end starts the 0.35 s return flight")
	step(s,.4);verify(s.phase=="ready" and not s.is_sealed(),"ready gourd usable after returning")
	# active brother: saved and restored without heal, refresh or replay
	s.reset(true);s.request();step(s,1.25);verify(s.phase=="active","brother active")
	s.brother.health=31;s.remaining=12.5;s.brother.pending_skill="fan"
	s.seal(2);await process_frame
	verify(s.brother==null and s.seal_resume.health==31,"active brother withdrawn with saved health")
	step(s,2.0+.45)
	verify(s.phase=="active" and is_instance_valid(s.brother) and s.brother.health==31 and absf(s.remaining-12.5)<.15,"brother returns with same health and assist time")
	verify(s.brother.pending_skill=="","interrupted skill is not replayed")
	# demon form restored without carry or extension
	s.brother.arrived=false;s.brother.arrive();var with_extension=s.remaining
	verify(game.player.is_carried(),"fresh bull arrival carries the hero in the knight arena")
	s.seal(1);await process_frame;step(s,1.45)
	verify(is_instance_valid(s.brother) and s.brother.demon and absf(s.remaining-with_extension)<.15,"demon form restored without extra time")
	# cooldown frozen
	s.reset(true);s.phase="cooldown";s.remaining=40;s.seal(5);step(s,5.45)
	verify(s.phase=="cooldown" and absf(s.remaining-40.0)<.15,"cooldown is frozen during the seal")
	# entering cancelled
	s.reset(true);s.request();step(s,.4);s.seal(2);await process_frame;step(s,2.45)
	verify(s.phase=="ready" and s.brother==null,"seal during entrance cancels it and returns to ready")
	# leaving → full cooldown
	s.reset(true);s.request();step(s,1.25);s.begin_leaving();s.seal(2);await process_frame;step(s,2.45)
	verify(s.phase=="cooldown" and absf(s.remaining-game.tuning.get_value("summon_cooldown"))<.15,"seal while leaving resumes as normal cooldown")
	# death, retry and stage change clear it
	s.seal(5);game.die("knight_wave");verify(not game.summon.is_sealed(),"death clears the seal")
	game.retry();await process_frame;await process_frame
	verify(game.boss.phase==1 and game.boss.hp==2400 and not game.summon.is_sealed(),"mounted-entry retry restarts mounted unless natural dismount was reached")
	game.summon.seal(5);game.jump_to_stage(1,0);await process_frame
	verify(not game.summon.is_sealed() and game.level.number==1 and game.boss.spec.id=="lantern","switching stage clears the seal; old boss intact")
	# killing the knight ends the seal and records the challenge
	var prior_wins=game.stage_record(4,"standard").get("completions",0)
	knight=await fresh();knight.phase=2;knight.hp=10;knight.max_hp=2400;game.summon.seal(8)
	knight.take_hit(50,"player",1)
	verify(knight.dead and game.summon.seal_return>0,"defeating the knight sends the gourd home")
	game.state="playing";game.challenge_finish=-1
	for i in 340:await physics_frame
	verify(game.state=="stage_clear" and game.stage_record(4,"standard").get("completions",0)==prior_wins+1,"challenge victory recorded in journey records")
	verify(game.progress.level==journey_level,"journey level still untouched after the challenge")
	game.audio.stop_all();game.queue_free();await process_frame;await process_frame;await create_timer(.2).timeout
	print("KNIGHT_BOSS_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
