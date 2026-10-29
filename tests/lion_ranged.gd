extends SceneTree
# Standing far away and shooting must not be a free win. Phase one catches
# frontal arrows and spits them back; phase two sways and rushes in. Shots from
# behind, or into a swing he already threw, still land.
var game
var boss
var checks=0
var failures=[]
func _initialize():call_deferred("run")
func verify(ok,label):
	checks+=1
	if not ok:failures.append(label);push_error("FAIL "+label)
func reset(phase):
	game.state="playing";game.hitstop=0;game.player.health=100;game.player.invincible=0;game.player.roll_guard=0
	game.progress["journey_mode"]="standard"
	game.combat.shots.clear()
	boss.clear_attacks();boss.phase=phase;boss.body_height=120 if phase==1 else 86
	boss.phase_shift=0;boss.stagger_left=0;boss.stagger_kind="";boss.turn_left=0;boss.dead=false
	boss.hp=boss.max_hp;boss.active_battle=true;boss.idle=0;boss.caught=0;boss.pending_spit=false
	boss.pending_rush=false;boss.ranged_ready=0;boss.far_time=0;boss.since_rest=0;boss.rest_ready=99
	boss.history.clear();boss.phase_moves=6;boss.sway_ready=0;boss.sway_left=0;boss.cancelled=false
	boss.position=Vector2(300,450);boss.facing=1
	game.player.position=Vector2(900,450);game.player.facing=-1
func step(seconds,shoot_every=0.0):
	var delta=1.0/120;var clock=0.0
	for i in int(ceil(seconds/delta)):
		game.hitstop=0
		if shoot_every>0:
			clock+=delta
			if clock>=shoot_every:
				clock=0;game.player.facing=signf(boss.position.x-game.player.position.x)
				game.combat.player_shot(game.player)
		game.player.invincible=maxf(0,game.player.invincible-delta)
		boss._physics_process(delta);game.combat._physics_process(delta)
func shot_into(direction):
	game.combat.fire(boss.position+Vector2(-direction*40,-50),Vector2(direction*650,0),23.0,"player","arrow")
	for i in 12:game.combat._physics_process(1.0/120)
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true
	game.start_new();await process_frame
	game.jump_to_stage(5);await process_frame
	boss=game.boss
	boss.set_physics_process(false);game.set_physics_process(false);game.player.set_physics_process(false);game.summon.set_physics_process(false);game.combat.set_physics_process(false)
	seed(88)
	game.tuning.reset()
	var saved=game.tuning.values.duplicate()
	# Phase one: frontal arrows are caught, a back shot lands.
	reset(1);var hp=boss.hp
	shot_into(-1);verify(boss.hp==hp and boss.caught==1,"lion head catches a frontal arrow")
	shot_into(1);verify(boss.hp<hp,"arrow into his back still lands")
	reset(1);shot_into(-1);shot_into(-1);boss.ranged_ready=0
	verify(boss.pending_spit,"two caught arrows queue a spit")
	step(.05);verify(boss.action=="spit","he spits right away")
	step(2.4);verify(game.player.health<100,"spat arrows reach a far archer")
	# Opening: once a swing is thrown, the front is open.
	reset(1);game.player.position=Vector2(380,450);boss.begin("M02");boss.t=boss.beats[0].time+.05;hp=boss.hp
	shot_into(-1);verify(boss.hp<hp,"shooting into a thrown swing lands")
	# Phase one: staying far without shooting still draws lantern fire.
	reset(1);step(4.0);verify(game.player.health<100,"far player gets lantern fire within four seconds")
	# Phase two: sway out of a frontal shot, then rush into the face.
	game.tuning.values["lion_sway_chance"]=100.0
	reset(2);hp=boss.hp;shot_into(-1)
	verify(boss.hp==hp and boss.pending_rush,"drunk sway dodges a frontal arrow and plans a rush")
	step(.05);verify(boss.action=="rush","rush starts")
	step(2.0);verify(absf(game.player.position.x-boss.position.x)<=boss.cfg("rush_stop")+30,"rush ends in the archer's face")
	game.tuning.values=saved.duplicate()
	reset(2);step(4.0);verify(absf(game.player.position.x-boss.position.x)<200,"far player in phase two gets chased down")
	# Kiting archer: stand at the far wall and fire nonstop. It must cost real health.
	for phase in [1,2]:
		reset(phase);game.player.position=Vector2(930,450);hp=boss.hp
		var lost=0.0
		for i in 20:
			step(1.0,.5)
			lost+=100-game.player.health;game.player.health=100
			game.player.position=Vector2(930,450)
		print("KITE phase=",phase," player_lost=",lost," boss_lost=",hp-boss.hp)
		verify(lost>=60,"kiting archer loses real health in phase "+str(phase))
	# Capacity is finite; magic and cards cannot be swallowed as ordinary arrows.
	reset(1)
	var arrow={"faction":"player","kind":"arrow","v":Vector2(-650,0)}
	for i in int(boss.cfg("catch_limit")):verify(boss.answer_projectile(arrow),"catch within capacity")
	verify(not boss.answer_projectile(arrow),"full mouth lets the next arrow land")
	for kind in ["flame","wave","card"]:
		verify(not boss.answer_projectile({"faction":"player","kind":kind,"v":Vector2(-650,0)}),"cannot swallow "+kind)
	verify(not boss.answer_projectile({"faction":"brother","kind":"arrow","v":Vector2(-650,0)}),"brother keeps his projectile role")
	reset(2);game.tuning.values["lion_sway_chance"]=100
	verify(boss.answer_projectile(arrow),"ready sway avoids one arrow")
	verify(not boss.answer_projectile(arrow),"sway cannot repeatedly erase arrows")
	# A released projectile survives ordinary next moves, but not an interruption.
	reset(1);boss.begin_spit(false);boss.advance_action(boss.cfg("spit_windup")+.01)
	var owned=game.combat.shots.filter(func(s):return s.owner==boss.get_instance_id())
	verify(owned.size()==1,"spit creates an owned projectile")
	boss.begin("M01")
	verify(game.combat.shots.any(func(s):return s.owner==boss.get_instance_id()),"next move preserves flying shot")
	boss.stagger("counter_head",1)
	verify(not game.combat.shots.any(func(s):return s.owner==boss.get_instance_id()),"counter clears flying shots")
	# Fixed charge: readable startup, one contact, no tracking, recovery open to arrows.
	for phase in [1,2]:
		for face in [-1,1]:
			reset(phase);boss.position.x=480;boss.facing=face
			game.player.position=Vector2(480+face*200,450);boss.begin_rush()
			var endpoint=boss.origin.x+face*boss.move.distance
			step(boss.cfg("rush_windup")-.02)
			verify(game.player.health==100 and boss.position.x==480,"charge tell harmless and stationary")
			step(.65)
			verify(game.player.health==64,"committed shoulder hits once at standard damage")
			verify(is_equal_approx(boss.position.x,endpoint),"charge reaches promised endpoint")
			hp=boss.hp;shot_into(-face)
			verify(boss.hp<hp,"charge recovery accepts frontal arrow")
			reset(phase);boss.position.x=480;boss.facing=face
			game.player.position=Vector2(480+face*200,450);boss.begin_rush()
			endpoint=boss.origin.x+face*boss.move.distance
			game.player.position=Vector2(480-face*100,450);step(1.1)
			verify(game.player.health==100 and is_equal_approx(boss.position.x,endpoint),"crossing behind avoids charge without retarget")
			reset(phase);boss.position.x=480;boss.facing=face
			game.player.position=Vector2(480+face*200,340);boss.begin_rush();step(1.1)
			verify(game.player.health==100,"jump clears committed shoulder")
	game.tuning.values=saved.duplicate()
	# Moving archer uses real run speed and .48s bow cadence, with .8s damage i-frames.
	# No teleports, no health reset: report actual survival and loss per encounter.
	for phase in [1,2]:
		for trial_seed in [7,88,2026]:
			seed(trial_seed);reset(phase);game.player.position=Vector2(850,450)
			var elapsed=0.0;var next_arrow=0.0;var close_frames=0;var run_direction=1
			while elapsed<25 and game.state=="playing":
				var dt=1.0/120
				var p=game.player
				p.invincible=maxf(0,p.invincible-dt)
				# Run all the way to the opposite wall, crossing him without teleporting.
				if p.position.x>=boss.arena.end.x-12:run_direction=-1
				elif p.position.x<=boss.arena.position.x+12:run_direction=1
				p.position.x=clampf(p.position.x+run_direction*p.SPEED*dt,boss.arena.position.x+10,boss.arena.end.x-10)
				if elapsed>=next_arrow:
					p.facing=signf(boss.position.x-p.position.x);game.combat.player_shot(p);next_arrow+=.48
				game.hitstop=0;boss._physics_process(dt);game.combat._physics_process(dt)
				if absf(p.position.x-boss.position.x)<120:close_frames+=1
				elapsed+=dt
			print("MOVING_ARCHER phase=",phase," seed=",trial_seed," seconds=",elapsed," player_hp=",game.player.health," boss_lost=",boss.max_hp-boss.hp," close_frames=",close_frames)
			verify(game.player.health<100 and close_frames>0,"moving archer faces damage and close pressure "+str(phase)+"/"+str(trial_seed))
	# Direct pose selection and simulation use the same authored left-facing source.
	for face in [-1,1]:
		boss.facing=face;boss.clear_attacks()
		boss.visual.pose("common_lion",0,true)
		verify(boss.visual.facing==-face,"common lion faces the committed direction")
		boss.visual.pose("common_elder",2,true)
		verify(boss.visual.facing==-face,"running elder faces the committed direction")
		boss.begin("M01");boss.visual.sync_pose(0)
		verify(boss.visual.facing==-face,"authored attack retains source heading")
	game.tuning.values=saved
	print("LION_RANGED_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
