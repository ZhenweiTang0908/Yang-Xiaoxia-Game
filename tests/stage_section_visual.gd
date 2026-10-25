extends SceneTree

func _initialize():
	call_deferred("run")

func run():
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.qa_mode=true
	game.start_new(false)
	for stage in [1,2,3]:
		game.load_stage(stage,0)
		for enemy in game.enemies:
			enemy.set_physics_process(false)
		for section in 4:
			var focus=section*4000.0+760.0
			game.player.position=Vector2(focus,450)
			game.player.velocity=Vector2.ZERO
			game.player.invincible=0
			game.camera.position=Vector2(focus,270)
			game.hint_time=0
			await create_timer(.08).timeout
			game.terrain.presence.step(game.player.position,true)
			await create_timer(.04).timeout
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(
				"res://builds/qa/stage-%s-section-%s.png"%[stage,section+1]
			)
	game.audio.stop_all()
	game.queue_free()
	await process_frame
	quit()
