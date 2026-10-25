extends SceneTree
var game
func _initialize():call_deferred("run")
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false);await process_frame
	var p=game.player;p.position=Vector2(900,450);game.camera.position=Vector2(900,270);p.invincible=.23;p.roll_guard=.23;p.dash_time=.18;p.sprinting=false;p.rage=25;p.spirit=30
	p.take_damage(20,1,"dart")
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/private/tmp/yang-perfect-dodge.png")
	game.audio.stop_all();game.queue_free();await process_frame;quit()
