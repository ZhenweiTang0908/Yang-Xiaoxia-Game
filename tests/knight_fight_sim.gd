extends SceneTree
# Runs the full knight fight through the real game loop with a scripted, kept-alive
# hero to exercise every action, the dismount and victory without script errors.
var game
var failures=[]
func verify(condition,label):
	if condition:print("PASS ",label)
	else:failures.append(label);push_error("FAIL "+label)
func _initialize():call_deferred("run")
func run():
	seed(91)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true
	game.start_new(false);await process_frame
	game.start_challenge();await process_frame
	var knight=game.boss;var frames=0;var dismounted=false;var hits=0;var last_health=100.0
	var rng=RandomNumberGenerator.new();rng.seed=91
	var press=func(action,on):
		if on:Input.action_press(action)
		else:Input.action_release(action)
	var direction=1
	game.summon.request()
	while frames<60*150 and not knight.dead:
		await physics_frame;frames+=1
		if game.state=="dead":game.retry();await process_frame;await process_frame;knight=game.boss;continue
		if game.state!="playing":continue
		var p=game.player
		if p.health<last_health:hits+=1
		p.health=100;last_health=100
		if frames%40==0:direction=-1 if rng.randf()<.5 else 1
		press.call("left",direction<0);press.call("right",direction>0)
		if frames%23==0:p.enqueue("attack")
		if frames%71==0:p.enqueue("jump")
		if frames%97==0:p.enqueue("dash")
		if frames%180==0:p.enqueue("bow")
		if knight.phase==2:dismounted=true
		var has_bow=knight.shown_moves.has("bow") or knight.shown_moves.has("bow_double") or knight.shown_moves.has("bow_volley")
		# Keep the foot phase alive until both its arena-wide and ranged attacks appear.
		var has_wave=knight.shown_moves.has("wave") or knight.shown_moves.has("dragon_break")
		var may_finish=knight.phase==1 or (has_wave and has_bow)
		if frames%30==0 and knight.active_battle and knight.phase_shift<=0 and may_finish:knight.take_hit(45 if knight.phase==1 else 14,"player",1)
	press.call("left",false);press.call("right",false)
	verify(dismounted,"fight reached the foot phase")
	verify(knight.dead,"fight reached victory")
	# Mounted-only catalogue of the first phase; these names must track the
	# knight's current move ids so the check keeps testing the horse, not a
	# renamed or retired id.
	var mounted=["charge","double_charge","halt_thrust","trample","rein"].filter(func(id):return knight.shown_moves.has(id))
	print("moves seen: ",knight.shown_moves.keys()," hero hits ",hits," frames ",frames)
	verify(mounted.size()>=2,"mounted techniques were used")
	var has_bow=knight.shown_moves.has("bow") or knight.shown_moves.has("bow_double") or knight.shown_moves.has("bow_volley")
	verify((knight.shown_moves.has("wave") or knight.shown_moves.has("dragon_break")) and has_bow,"an arena-wide spear release and a bow technique were used")
	for i in 420:await physics_frame
	verify(game.state=="stage_clear","victory shows the challenge result")
	game.audio.stop_all();game.queue_free();await process_frame;await create_timer(.2).timeout
	print("KNIGHT_FIGHT_SIM failures=",failures)
	quit(0 if failures.is_empty() else 1)
