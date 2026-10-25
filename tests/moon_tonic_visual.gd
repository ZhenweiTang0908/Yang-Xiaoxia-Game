extends SceneTree
var game
func _initialize():call_deferred("run")
func capture(path):
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func run():
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.developer_mode=false;game.start_new(false);await process_frame
	game.player.position=Vector2(920,450);game.camera.position=Vector2(920,270);game.last_section=0;game.player.health=42;game.progress.tonic=2;game.use_tonic()
	await capture("/private/tmp/yang-moon-tonic-hud.png")
	game.is_touch=true;game.hint_time=0
	await capture("/private/tmp/yang-moon-tonic-touch.png")
	game.state="controls";game.hud.controls_return="paused";game.gamepad.glyphs="switch";game.pad_mode=true
	await capture("/private/tmp/yang-moon-tonic-controls.png")
	game.audio.stop_all();game.queue_free();await process_frame;quit()
