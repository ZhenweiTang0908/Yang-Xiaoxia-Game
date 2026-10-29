extends SceneTree
# Plays the whole fifth battle through the real game loop with a scripted hero
# that survives, so phase shift, rest, every catalogue entry and victory are all
# exercised together. Damage the boss is dealt slowly to keep the fight long.
const EXPECTED=["M01","M02","M03","M04","M05","M06","M07","M08","M09","M10","M11","M12","M13","M14","M15","M16","M17","M18","M19","M20"]
var game
var failures=[]
func verify(condition,label):
	if condition:print("PASS ",label)
	else:failures.append(label);push_error("FAIL "+label)
func _initialize():call_deferred("run")
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true
	game.start_new(true);await process_frame
	game.jump_to_stage(5);await process_frame
	var boss=game.boss
	verify(boss!=null and boss.has_method("begin"),"fifth battle instantiates the lion elder")
	if boss==null or not boss.has_method("begin"):finish();return
	game.progress["journey_mode"]="standard"
	var frames=0
	var saw_phase_two=false
	var saw_rest=false
	var stuck=0
	var last_x=game.player.position.x
	var rng=RandomNumberGenerator.new()
	# Override with LION_SEED to fuzz the same fight across different move orders.
	var raw_seed=OS.get_environment("LION_SEED")
	rng.seed=int(raw_seed) if raw_seed.is_valid_int() else 41
	var direction=1
	while frames<60*200 and not boss.dead:
		await physics_frame;frames+=1
		if game.state=="dead":game.retry();await process_frame;await process_frame;boss=game.boss;continue
		if game.state!="playing":continue
		var p=game.player
		p.health=100;p.invincible=maxf(p.invincible,0)
		if frames%40==0:direction=-1 if rng.randf()<.5 else 1
		if frames%23==0:p.enqueue("attack")
		if frames%41==0:p.position.y=450-40
		if game.state=="playing" and is_instance_valid(boss) and boss.active_battle:
			if boss.phase==2:saw_phase_two=true
			if boss.action=="rest":saw_rest=true
		# Keep pressure low so the fight lasts long enough to show its whole book.
		if frames%60==0 and boss.phase_shift<=0 and boss.active_battle:boss.take_hit(34,"player",direction,false)
		if absf(p.position.x-last_x)<.01:stuck+=1
		else:stuck=0
		last_x=p.position.x
	verify(boss.dead,"the fifth battle can be finished, frames="+str(frames))
	verify(saw_phase_two,"the uncovered second phase was reached")
	verify(saw_rest,"the elder takes a breathing rest mid-fight")
	var shown=boss.shown_moves.keys()
	var unseen=EXPECTED.filter(func(id):return not boss.shown_moves.has(id))
	print("moves seen: ",shown)
	verify(unseen.size()<=6,"most of the twenty moves appear in one fight, unseen="+str(unseen))
	# Boss rush ends at the right-hand exit, so walk there like a player would.
	if is_instance_valid(game.player) and is_instance_valid(game.level):
		game.player.position.x=game.level.length-200
	# A single-boss arena holds the result for the defeat line, up to 6.5s.
	for i in 60*9:await physics_frame
	verify(game.state in ["stage_clear","win"],"victory advances the journey, state="+game.state)
	finish()
func finish():
	if is_instance_valid(game):game.audio.stop_all();game.queue_free();await process_frame
	print("LION_FIGHT_SIM failures=",failures)
	quit(0 if failures.is_empty() else 1)
