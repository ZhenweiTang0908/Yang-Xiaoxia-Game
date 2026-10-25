extends SceneTree
var game
var results=[]
func _initialize():call_deferred("run")
func trial(knight,seed_value,jumping):
	seed(seed_value)
	if knight:game.start_challenge(4,2)
	else:game.jump_to_stage(3,2)
	await process_frame;await physics_frame;await physics_frame
	var boss=game.boss
	boss.active_battle=true
	if not knight:boss.hp=boss.max_hp*.25;boss.phase=3;boss.phase_shift=0
	for e in game.enemies:if e!=boss:e.set_physics_process(false)
	game.summon.reset(true);game.progress.upgrades=[];game.progress.journey_mode="standard"
	game.checkpoint_index=game.level.checkpoints.size()-1;game.progress.pending_upgrade={};game.state="playing"
	var arena=boss.arena;var p=game.player
	p.position=Vector2(arena.position.x+90,450);p.velocity=Vector2.ZERO;p.health=100;p.invincible=0
	boss.position=Vector2(arena.get_center().x,450)
	var damage=0.0;var contacts=0;var direction=1;var close_frames=0;var frames=60*35
	for i in frames:
		if p.position.x>arena.end.x-55:direction=-1
		if p.position.x<arena.position.x+55:direction=1
		Input.action_press("right") if direction>0 else Input.action_release("right")
		Input.action_press("left") if direction<0 else Input.action_release("left")
		if jumping and i%105==0:p.enqueue("jump");Input.action_press("jump")
		if jumping and i%105==16:Input.action_release("jump")
		p.health=100
		await physics_frame
		if p.health<100:contacts+=1;damage+=100-p.health
		if absf(p.position.x-boss.position.x)<180:close_frames+=1
	Input.action_release("left");Input.action_release("right");Input.action_release("jump")
	var row={"boss":"knight_foot" if knight else "priest_final_phase","seed":seed_value,"jumping":jumping,"seconds":35,"contacts":contacts,"damage":damage,"close_ratio":float(close_frames)/frames,"moves":boss.shown_moves.keys()}
	results.append(row);print("RUNNER ",JSON.stringify(row))
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false);await process_frame
	for jumping in [false,true]:
		for value in [1701,1702]:
			await trial(false,value,jumping)
			await trial(true,value,jumping)
	var knight_damage=0.0;var priest_damage=0.0
	for row in results:
		if row.boss=="knight_foot":knight_damage+=row.damage
		else:priest_damage+=row.damage
	var output={"scenarios":results,"knight_damage":knight_damage,"priest_damage":priest_damage,"ratio":knight_damage/maxf(1,priest_damage),"scope":"same unupgraded human hero, no attacks/assist/healing; sustained run or run+jump; priest strongest phase; not a human difficulty rating"}
	FileAccess.open("res://builds/qa/knight/pressure-runner.json",FileAccess.WRITE).store_string(JSON.stringify(output,"  "))
	var passed=priest_damage>0 and knight_damage>priest_damage*1.1
	print("PRESSURE_RUNNER knight=",knight_damage," priest=",priest_damage," stronger_pressure=",passed)
	game.audio.stop_all();game.queue_free();await process_frame;quit(0 if passed else 1)
