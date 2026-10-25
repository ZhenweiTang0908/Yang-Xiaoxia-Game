extends SceneTree
var game
var k
var failures=[]
var checks=0
func _initialize():call_deferred("run")
func verify(ok,label):
	checks+=1
	if not ok:failures.append(label);push_error(label)
	else:print("PASS ",label)
func reset(id,x=500.0,y=450.0):
	game.combat.clear();game.state="playing";game.hitstop=0
	game.player.position=Vector2(x,y);game.player.health=100;game.player.invincible=0;game.player.roll_guard=0;game.player.form_transition=0
	k.end_box();k.phase=1 if id in ["advance","uppercut"] else 2;k.landed=k.phase==2;k.dismount_t=-1;k.dead=false
	k.position=Vector2(400,450);k.facing=1;k.weapon=k.weapon_for(id);k.visual.held_action="";k.idle=100;k.begin(id,k.prep_for(id))
func step(seconds):
	for i in int(round(seconds*120)):
		game.hitstop=0;game.player.invincible=maxf(0,game.player.invincible-1.0/120)
		game.combat._physics_process(1.0/120);k._physics_process(1.0/120)
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true
	game.start_new(false);await process_frame;game.start_challenge();await process_frame
	k=game.boss;k.active_battle=true;k.set_physics_process(false);game.player.set_physics_process(false)
	game.combat.set_physics_process(false);game.summon.set_physics_process(false)
	game.progress.journey_mode="standard"
	for id in k.NEW_MOVES:
		reset(id)
		step(k.prep_for(id)-.025)
		verify(game.player.health==100,id+" cannot deal damage before its windup")
		verify(k.visual.selected in [k.visual.arsenal,k.visual.mounted_arsenal],id+" uses its new painted windup")
		for stage in ["warning","release","impact"]:
			var key="knight_"+id+"_"+stage
			verify(ResourceLoader.exists("res://assets/audio/"+key+".wav"),key+" imported")
	reset("advance",505);step(.65)
	verify(game.player.health==84,"first advancing hoof deals 16")
	game.player.position.x=535;game.player.invincible=0;step(.5)
	verify(game.player.health==68,"second hoof has independent contact")
	game.player.position.x=563;game.player.invincible=0;step(.5)
	verify(game.player.health==52,"third hoof completes the regular rhythm")
	verify(absf(k.position.x-484)<.1,"three hooves travel exactly 84 px")
	reset("uppercut",450);step(.85)
	verify(game.player.health==100,"upward lance passes above a standing hero")
	reset("uppercut",450,380);step(.85)
	verify(game.player.health==78,"upward lance punishes an airborne hero")
	reset("lunge",640);step(1.12)
	verify(game.player.health==74,"moving lance hits a target along the swept path exactly once")
	verify(absf(k.position.x-554)<.1 and k.hit_box==null,"lunge travels 154 px and removes its moving hitbox")
	reset("lunge",640,375);step(1.12)
	verify(game.player.health==100,"jump clears the waist-height lunge")
	reset("kick_thrust",450);step(.65)
	verify(game.player.health==90,"kick opener deals 10")
	step(.85);verify(game.player.health==70,"visible spear followup deals 20")
	reset("cross_cut",480);step(.75)
	verify(game.player.health==84,"cross-cut opener deals 16")
	game.player.position.x=350;step(.25)
	verify(k.facing==-1,"return cut reorients at the start of its visible windup")
	game.player.position.x=480;step(.30)
	verify(k.facing==-1,"return cut cannot track through its final windup")
	game.player.position.x=350;step(.30)
	verify(game.player.health==64,"cross-cut return deals 20")
	reset("bow_double",800);step(.72)
	verify(game.combat.shots.size()==1,"first draw releases one arrow")
	var first=game.combat.shots[0]
	verify(first.attack_sound=="knight:bow_double" and first.seal==7,"arrow retains its sound identity and hit-only 7 s seal")
	step(.91)
	verify(k.fired.has("arrow1"),"second independent draw releases its second arrow")
	verify(not game.summon.is_sealed() or game.player.health<100,"arrow only seals when it actually hits")
	reset("bow_double",800);step(.46)
	var locked=k.aim;game.player.position=Vector2(200,360);step(.25)
	verify(k.aim.is_equal_approx(locked) and k.facing==1,"first arrow stops tracking 0.25 s before release")
	step(.45);verify(k.facing==-1,"second draw independently reacquires the moved hero")
	reset("bow_double",600);game.summon.reset(true);step(1.25)
	verify(game.player.health==88 and game.summon.is_sealed(),"a real double-bow arrow hits for 12 and seals the gourd")
	reset("lunge");step(.75)
	var art=k.visual.arsenal
	var info=art.frame_info[5];var tip=Vector2(372-info.source_rect[0]+8-info.anchor,600-info.source_rect[1]+8-art.bounds[5].end.y)*art.scale_unit
	var painted=art.deform(tip)
	verify(painted.y>=-43 and painted.y<=-15,"lowered painted lance tip matches the actual damage band")
	# New techniques are eligible in their intended range; recent long chains cannot repeat.
	var seen={}
	for phase in [1,2]:
		for distance in [50,140,250,400]:
			for i in 35:
				reset("advance" if phase==1 else "lunge",400+distance)
				k.history=[];k.sets_since_wave=5;k.choose()
				seen[k.pending if k.action=="switch" else k.action]=true
	for id in k.NEW_MOVES:verify(seen.has(id),id+" is reachable through normal AI")
	k.history=["cross_cut"]
	verify(k.without_chained_combos(["cross_cut","bow_double","thrust"])==["thrust"],"long combos require an intervening ordinary move")
	reset("lunge",640);step(.75);k.hp=1;k.take_hit(999,"player",1)
	verify(k.dead and k.hit_box==null,"death cancels a live lance hitbox")
	game.audio.stop_all();game.queue_free();await process_frame
	print("KNIGHT_ARSENAL checks=",checks," failures=",failures);quit(0 if failures.is_empty() else 1)
