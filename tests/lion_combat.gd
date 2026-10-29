extends SceneTree
var game
var boss
var checks=0
var failures=[]
func _initialize():call_deferred("run")
func verify(ok,label):
	checks+=1
	if not ok:failures.append(label);push_error("FAIL "+label)
func reset(id,face=1.0):
	game.state="playing";game.hitstop=0;game.player.health=100;game.player.invincible=0;game.player.roll_guard=0
	# Damage assertions must not depend on the locally saved journey difficulty.
	game.progress["journey_mode"]="standard";game.tuning.values["lion_damage_scale"]=1.0
	game.player.position=Vector2(900,450);boss.position=Vector2(400,450);boss.facing=face
	boss.phase=1 if int(id.substr(1))<=8 or id=="M19" else 2
	boss.phase_shift=0;boss.stagger_left=0;boss.stagger_kind="";boss.whiff_ready=0;boss.turn_left=0;boss.dead=false;boss.hp=boss.max_hp;boss.active_battle=true;boss.damage_log.clear()
	boss.begin(id)
func step(seconds):
	var delta=1.0/120
	for i in int(ceil(seconds/delta)):
		game.hitstop=0
		boss._physics_process(delta)
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true
	game.start_new();await process_frame
	game.jump_to_stage(5);await process_frame
	boss=game.boss
	verify(boss!=null and boss.has_method("begin"),"fifth route actually instantiates dedicated actor")
	if boss==null or not boss.has_method("begin"):finish();return
	boss.set_physics_process(false);game.set_physics_process(false);game.player.set_physics_process(false);game.summon.set_physics_process(false);game.combat.set_physics_process(false)
	for id in boss.CATALOG.MOVES:
		for face in [-1.0,1.0]:
			reset(id,face)
			var first=boss.beats[0].time
			game.player.position=Vector2(400+face*30,450)
			step(first-.025)
			verify(game.player.health==100,id+" no windup damage "+str(face))
			verify(boss.facing==face or id=="M14",id+" committed facing before hit")
	reset("M14");game.player.position=Vector2(440,450);step(.81)
	verify(boss.position.x<400 and boss.lock_dir==1,"inviting retreat moves away while committed kick points toward pursuer")
	reset("M09");game.player.position=Vector2(435,450)
	step(.86);verify(game.player.health==82,"short elbow hits for18")
	game.player.invincible=0;step(.10);verify(game.player.health==82,"same elbow cannot hit twice after invulnerability clears")
	reset("M06");game.player.position=Vector2(445,450);step(1.1);verify(game.player.health==100,"high lion sweep leaves ground path safe")
	reset("M02");game.player.position=Vector2(445,380);step(1.1);verify(game.player.health==100,"jump clears low foot")
	reset("M01");game.player.position=Vector2(600,450);step(1.10);verify(game.player.health==80,"swept moving lion hits target inside its painted travel")
	# Authored airborne support now carries the painted nose through x626.
	reset("M01");game.player.position=Vector2(650,450);step(1.10);verify(game.player.health==100,"target beyond full painted pounce travel remains safe")
	reset("M09");game.player.position=Vector2(435,450);game.player.invincible=2;game.player.roll_guard=2;game.player.rage=0;game.player.spirit=0
	step(.9);verify(game.player.health==100 and game.player.dodge_rewarded,"new contact source earns real perfect dodge")
	reset("M03");boss.t=.6;boss.take_hit(10,"player",1,true)
	verify(boss.action=="" and boss.stagger_kind=="counter_head" and boss.stagger_left>1,"breaking strike exposes lion head stumble")
	reset("M03");boss.t=.1;boss.take_hit(10,"player",1,true)
	verify(boss.action=="M03","outside break window damage does not cancel attack")
	reset("M13");boss.t=1.05;boss.take_hit(10,"player",1,true)
	verify(boss.stagger_kind=="counter_support","breaking strike removes handstand support")
	reset("M15");boss.t=.6;boss.take_hit(10,"player",1,false)
	verify(boss.action=="M15","ordinary melee does not fake arrow counter")
	boss.on_projectile_contact({"faction":"player"});boss.take_hit(10,"player",1,false)
	verify(boss.stagger_kind=="counter_gourd" and boss.action=="","projectile body hit makes gourd miss")
	# Breathers rotate: any three in a row are all different, gags never hurt,
	# and only the sip can be knocked out of his hands.
	reset("M09");boss.rest_history.clear()
	var seen={};var recent=[]
	for i in 30:
		boss.begin_rest();recent.append(boss.rest_kind);seen[boss.rest_kind]=true
		if recent.size()>=3:verify(recent.slice(-3).duplicate().filter(func(k):return k==boss.rest_kind).size()==1,"breather never repeats within three "+str(i))
	verify(seen.size()==boss.RESTS.size(),"every breather appears over a fight")
	for kind in boss.RESTS:
		reset("M09");game.player.position=Vector2(420,450);boss.begin_rest();boss.rest_kind=kind
		step(.6);verify(game.player.health==100,kind+" breather deals no damage")
		boss.take_hit(10,"player",1,false)
		verify((boss.stagger_kind=="counter_gourd")==(kind=="sip"),kind+" breather interrupt rule")
		if kind!="sip":
			boss.stagger_left=0;boss.stagger_kind="";step(1.2)
			verify(boss.action!="rest",kind+" breather ends inside 1.1s design limit")
	reset("M01");boss.hp=boss.max_hp*.55+1;boss.take_hit(2,"player",1)
	verify(boss.phase==2 and boss.phase_shift>=1.9 and boss.action=="" and boss.beats.is_empty(),"phase crossing clears old action and protects reposition")
	reset("M09");boss.take_hit(99999,"player",1)
	verify(boss.dead and boss.action=="" and boss.beats.is_empty(),"defeat clears every pending contact")
	reset("M09");game.state="dead";boss._physics_process(.1)
	verify(boss.action=="" and boss.beats.is_empty(),"player death clears contacts")
	reset("M09");game.state="paused";var old=boss.t;boss._physics_process(.5)
	verify(boss.t==old,"pause freezes action clock")
	reset("M01");boss.position.x=910;boss.origin=boss.position;step(1.1)
	verify(boss.position.x<=920,"moving attack stops at wall without rebound")
	# Relaxed journey applies its documented 0.7 incoming multiplier.
	reset("M09");game.progress["journey_mode"]="relaxed";game.player.position=Vector2(435,450)
	step(.86);verify(absf(game.player.health-87.4)<.05,"relaxed journey scales lion damage")
	game.progress["journey_mode"]="standard";game.tuning.values["lion_damage_scale"]=1.0
	for side in [-1.0,1.0]:
		reset("M01",side);boss.position.x=200 if side<0 else 760
		boss.begin_phase_shift()
		var expected=boss.phase_drop_position
		step(boss.phase_total-.025)
		verify(not is_instance_valid(boss.head_prop),"transition painted head has no duplicate prop "+str(side))
		step(.04)
		verify(is_instance_valid(boss.head_prop),"transition leaves head prop "+str(side))
		verify(boss.position.distance_to(expected)<.01 and boss.phase_shift==0,"protected walk reaches side before fists "+str(side))
		if is_instance_valid(boss.head_prop):
			var placed=boss.head_prop.position
			boss.position.x-=side*80
			verify(boss.head_prop.position==placed and boss.head_prop.get_parent()==game.world,"head stays on floor as elder walks away "+str(side))
			boss.head_prop.free();boss.head_prop=null
	# A heavy swing that touches nobody leaves him embarrassed; a landed one does not.
	var saved=game.tuning.values.duplicate()
	game.tuning.values["lion_whiff_chance"]=100.0
	game.tuning.values["lion_M09_0_damage"]=30.0
	reset("M09");game.player.position=Vector2(900,450);step(1.9)
	verify(boss.stagger_kind=="perfect_dodge" and boss.stagger_left>0,"heavy whiff leaves him embarrassed")
	# The next whiff inside the cooldown must not hand out a second free punish.
	boss.stagger_left=0;boss.stagger_kind="";boss.begin("M09");game.player.position=Vector2(900,450);step(1.9)
	verify(boss.stagger_kind!="perfect_dodge","whiff stumble respects its cooldown")
	reset("M09");game.player.position=Vector2(435,450);step(1.9)
	verify(game.player.health<100 and boss.stagger_kind!="perfect_dodge","landed heavy hit gives no free stumble")
	game.tuning.values["lion_M09_0_damage"]=18.0
	reset("M09");game.player.position=Vector2(900,450);step(1.9)
	verify(boss.stagger_kind!="perfect_dodge","light whiff stays composed")
	game.tuning.values=saved
	finish()
func finish():
	if is_instance_valid(game):game.audio.stop_all();game.queue_free();await process_frame
	print("LION_COMBAT_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
