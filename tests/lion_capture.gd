extends SceneTree
var game
var out="res://builds/qa/lion-elder/"
func _initialize():
	root.unfocusable=true
	call_deferred("run")
func shot(name):
	await process_frame;await process_frame
	RenderingServer.force_draw(false)
	var image=root.get_texture().get_image()
	if image==null or image.is_empty():push_error("Missing rendered image");quit(1);return
	var result=image.save_png(out+name+".png")
	if result!=OK:push_error("Cannot save rendered image");quit(1)
func run():
	DirAccess.make_dir_recursive_absolute(out)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true
	game.start_new();await process_frame
	game.jump_to_stage(5);await process_frame
	game.state="playing";game.stage_banner=-10
	game.set_physics_process(false);game.boss.set_physics_process(false);game.player.set_physics_process(false);game.combat.set_physics_process(false)
	game.boss.active_battle=true;game.boss.position=Vector2(640,450);game.player.position=Vector2(330,450);game.player.facing=1
	game.boss.visual.pose("common_lion",0,true)
	await shot("production-lion-idle")
	game.boss.phase=2;game.boss.body_height=86;game.boss.visual.pose("common_elder",0,true)
	await shot("production-elder-idle")
	for id in game.boss.CATALOG.MOVES:
		game.boss.begin(id)
		game.boss.t=game.boss.beats[0].time;game.boss.visual.sync_pose(0)
		await shot("contact-"+id)
	game.boss.phase=1;game.boss.begin_phase_shift()
	for index in 8:
		game.boss.position=game.boss.phase_drop_position
		game.boss.visual.pose("transition",index,true)
		await shot("transition-%02d"%index)
	game.boss.phase_shift=.001;game.hitstop=0;game.boss._physics_process(.002)
	await shot("transition-complete")
	# Explicit visual evidence for the pressure revision, with real rendering.
	game.boss.phase_shift=0;game.boss.stagger_left=0;game.boss.turn_left=0
	if is_instance_valid(game.boss.head_prop):game.boss.head_prop.queue_free();game.boss.head_prop=null
	game.boss.phase=1;game.boss.facing=-1;game.boss.position=Vector2(640,450)
	game.boss.clear_attacks();game.boss.caught=2
	game.boss.visual.pose("common_lion",0,true)
	await shot("pressure-mouth-full")
	game.boss.begin_spit(true);game.boss.advance_action(.3)
	await shot("pressure-spit-tell")
	game.boss.advance_action(.32)
	await shot("pressure-spit-release")
	game.combat.clear()
	game.boss.phase=2;game.boss.caught=0
	game.player.health=100;game.player.invincible=99
	game.boss.begin_rush();game.boss.advance_action(.2)
	await shot("pressure-rush-tell")
	game.boss.advance_action(.5)
	await shot("pressure-rush-travel")
	game.boss.advance_action(.65)
	await shot("pressure-rush-recovery")
	# A short silent motion preview: committed run into empty space and recovery.
	DirAccess.make_dir_recursive_absolute(out+"pressure-motion")
	game.boss.clear_attacks();game.boss.position=Vector2(740,450)
	game.boss.facing=-1;game.player.position=Vector2(330,450)
	game.boss.begin_rush();game.player.position.y=320
	for frame in 66:
		game.hitstop=0
		if game.boss.action!="":game.boss.advance_action(1.0/30)
		if game.boss.action=="":game.boss.visual.pose("common_elder",0,true)
		await shot("pressure-motion/%03d"%frame)
	game.audio.stop_all();game.queue_free();await process_frame
	print("LION_CAPTURE_RESULT captures=103 status=DRAFT_PRODUCTION_REVIEW")
	quit(0)
