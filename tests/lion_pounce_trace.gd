extends SceneTree
func _initialize():call_deferred("run")
func run():
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new();await process_frame;game.jump_to_stage(5);await process_frame
	game.set_physics_process(false);game.player.set_physics_process(false);game.combat.set_physics_process(false);game.boss.set_physics_process(false)
	var b=game.boss;b.active_battle=true;b.position=Vector2(400,450);b.facing=1;b.begin("M01");game.player.position=Vector2(900,450)
	for i in 132:
		game.hitstop=0;b._physics_process(1.0/120)
		if i%6==0 and b.t>=.77 and b.t<1.04:
			var cap=b.beat_rect(0,b.position.x,b.position.x);var xs=[]
			for x in range(400,641,2):
				if b.visual.silhouette_intersects(cap.intersection(Rect2(x-8,412,16,38)),b.position):xs.append(x)
			print("t=",b.t," root=",b.position.x," bank=",b.visual.active_bank," frame=",b.visual.frame," cap=",cap," standing_contact_range=",[xs[0],xs[-1]] if not xs.is_empty() else [])
	game.audio.stop_all();game.queue_free();await process_frame
	print("LION_POUNCE_TRACE_RESULT done")
	quit(0)
