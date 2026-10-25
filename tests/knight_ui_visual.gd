extends SceneTree
# Captures the challenge entrance, stage select, records, tuning panel and result.
var game
var folder="/private/tmp/yang-knight-ui/"
func _initialize():call_deferred("run")
func shot(name):
	for i in 3:await process_frame
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png(folder+name+".png")
func run():
	var args=OS.get_cmdline_user_args()
	if args.size()>0:folder=args[0]
	if not folder.ends_with("/"):folder+="/"
	DirAccess.make_dir_recursive_absolute(folder)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true
	await process_frame
	game.state="title";await shot("u1_title")
	game.hud.action("stage_select");await shot("u2_stage_select")
	game.hud.action("stage_select_back")
	game.start_challenge();await process_frame
	game.boss.active_battle=true;game.boss.phase=2;game.boss.hp=10;game.boss.max_hp=2400;game.boss.take_hit(50,"player",1)
	game.challenge_finish=-1
	for i in 200:await physics_frame
	await shot("u3_result")
	game.hud.action("journey_records");await shot("u4_records")
	game.hud.action("journey_records_back")
	game.state="playing";game.debug_panel.toggle()
	game.debug_panel.root.get_child(1).get_child(0).get_child(0).get_child(2).scroll_vertical=900
	await shot("u5_tuning")
	game.audio.stop_all();game.queue_free();await process_frame;quit()
