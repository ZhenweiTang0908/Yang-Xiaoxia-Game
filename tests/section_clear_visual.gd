extends SceneTree
var game

func _initialize():call_deferred("run")
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false)
	for i in 4:await process_frame
	game.player.position=Vector2(3000,450);game.camera.position=Vector2(3170,270);game.player.health=67;game.player.spirit=42
	var group=game.enemies.filter(func(enemy):return enemy.kind!="boss" and enemy.section==0)
	for enemy in group:enemy.dead=true;enemy.hide();enemy.set_physics_process(false)
	game.on_enemy_defeated(group.back())
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/private/tmp/yang-section-clear.png")
	game.audio.stop_all();game.queue_free();await process_frame;await process_frame;quit()
