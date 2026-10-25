extends SceneTree
var game
var failures=[]
var checks=0
func _initialize():call_deferred("run")
func verify(condition,label):
	checks+=1
	if condition:print("PASS ",label)
	else:failures.append(label);push_error("FAIL "+label)
func frames(count):
	for i in count:await physics_frame
	await process_frame
func disable_enemies():
	for e in game.enemies:e.set_physics_process(false)
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.tuning.reset();game.start_new(false);disable_enemies()
	await frames(12)
	var p=game.player
	verify(p is CharacterBody2D,"native character physics")
	verify(absf(p.art.body_height-52.8)<.01,"hero height 60 percent of old 88")
	p.position=Vector2(4860,450);p.velocity=Vector2.ZERO;await frames(5)
	p.enqueue("jump");Input.action_press("jump");await frames(54);Input.action_release("jump")
	verify(p.is_on_floor() and absf(p.position.y-370)<3,"jump through underside and land on thin platform")
	Input.action_press("down");p.enqueue("jump");await frames(40);Input.action_release("down")
	verify(p.is_on_floor() and absf(p.position.y-450)<3,"drop through platform to solid ground")
	p.position=Vector2(4990,370);p.velocity=Vector2.ZERO;await frames(3)
	Input.action_press("right");p.enqueue("jump");await frames(50);Input.action_release("right");await frames(15)
	verify(p.position.x>5120 and p.position.y<=371,"first gap can be crossed")
	# Upper route pickup is collected by the real overlap test.
	p.position=Vector2(690,450);p.velocity=Vector2.ZERO;await frames(3)
	verify(p.has_bow and game.progress.bow,"bow pickup persists")
	var target=game.enemies[0];target.position=Vector2(740,450);target.dead=false;target.hp=100
	p.position=Vector2(690,450);p.facing=1;p.enqueue("attack");var previous=target.hp
	await frames(3);verify(target.hp==previous,"melee respects anticipation frames")
	await frames(16);verify(target.hp<previous,"melee hits on active frames")
	game.hitstop=0;p.spirit=100;p.enqueue("transform");await frames(35)
	verify(p.sheep() and p.form_visual,"actual sheep visual swaps in")
	p.enqueue("bow");await frames(7)
	verify(game.combat.shots.any(func(s):return s.kind=="flame" and s.pierce==1),"sheep flame has one penetration")
	# Summon runs alongside movement; no player stun or input freeze.
	p.position=Vector2(2150,450);p.velocity=Vector2.ZERO;game.progress.gourd=true;game.summon.reset(true)
	game.combat.clear();game.hitstop=0
	for e in game.enemies:e.dead=true
	verify(game.summon.request(),"summon accepted when ready")
	verify(not game.summon.request(),"duplicate summon rejected")
	var start=p.position.x;Input.action_press("right");await frames(40);Input.action_release("right")
	verify(p.position.x>start+70,"player moves freely during gourd entry")
	verify(game.summon.phase=="entering","entry does not spend assist duration")
	await frames(35)
	verify(game.summon.phase=="active" and game.summon.remaining>29.5,"30 seconds starts after entry")
	verify(game.summon.brother.demon and absf(game.summon.brother.body_height-52)<.01,"companion directly uses the bull body")
	var remaining=game.summon.remaining;game.state="paused";await frames(120)
	verify(is_equal_approx(game.summon.remaining,remaining),"pause freezes summon timers")
	game.state="playing";await frames(1810)
	verify(game.summon.phase=="leaving","assist lasts full 30 seconds before leaving")
	await frames(50)
	verify(game.summon.phase=="cooldown" and game.summon.remaining>23.5,"25 second cooldown begins after exit")
	await frames(1530)
	verify(game.summon.phase=="ready","summon becomes ready after cooldown")
	verify(not p.sheep() and not p.form_visual,"sheep form expires and restores human")
	game.state="story";game.story_page=0;game.complete_story()
	verify(game.progress.story_seen and game.progress.gourd and game.state=="stage_clear","skip story grants gourd exactly once")
	for stage in [2,3]:
		game.load_stage(stage,2);disable_enemies();await frames(5)
		var b=game.boss;b.active_battle=true
		verify(b.spec.moves.size()==(7 if stage==2 else 10),"stage "+str(stage)+" exact boss move count")
		game.player.position=Vector2(14700,450);game.player.invincible=999
		for i in b.spec.moves.size():
			game.combat.clear();b.events.clear();b.position=Vector2(14900,450);b.start_move(i);b.release_move()
			for event in b.events:b.execute_event(event.type,event.payload)
			verify(game.combat.shots.size()+game.combat.hazards.size()>0,"boss action "+b.spec.moves[i].id+" creates attack")
		verify(b.shown_moves.size()==b.spec.moves.size(),"all boss moves reachable stage "+str(stage))
		b.take_hit(b.hp+1,"player",1);game.player.position.x=15800;game.finish_level()
		verify(game.state==("stage_clear" if stage==2 else "win"),"stage completion "+str(stage))
	var store=load("res://scripts/core/save_store.gd")
	var path="user://integration_save.json";var data=store.defaults();data.level=3;data.checkpoint=2;data.gourd=true;data.music=.4
	store.write_save(data,path);var restored=store.read_save(path)
	verify(restored.level==3 and restored.checkpoint==2 and restored.gourd and is_equal_approx(restored.music,.4),"save round-trip preserves progress and audio")
	DirAccess.remove_absolute(path)
	verify(game.audio.bank.size()>=40,"expanded audio event bank")
	for stage in [1,2,3]:
		for mood in ["explore","boss"]:
			var track=load("res://assets/music/level"+str(stage)+"_"+mood+".ogg")
			verify(track.get_length()>=(90 if mood=="explore" else 60),"music length stage "+str(stage)+" "+mood)
	game.state="paused";game.audio.stop_all();game.queue_free();await process_frame;await process_frame
	OS.delay_msec(200)
	print("INTEGRATION_RESULT checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
