extends SceneTree
var game
func _initialize():call_deferred("run")
func run():
	root.unfocusable=true
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.developer_mode=false
	await process_frame;await process_frame
	game.start_new(false);await process_frame
	game.player.health=1;game.player.invincible=0;game.player.take_damage(100,0,"spirit_lightning")
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/private/tmp/yang-death-guide.png")
	# Measure every authored hint with the actual UI font, rather than character counts.
	var pattern=RegEx.new();pattern.compile('"tip":"([^"]+)"')
	var tips=pattern.search_all(FileAccess.get_file_as_string("res://scripts/game.gd"))
	var widest=0.0
	for tip in tips:
		widest=maxf(widest,game.font.get_string_size(tip.get_string(1),HORIZONTAL_ALIGNMENT_LEFT,-1,12).x)
	game.death_source="soul_arrow";game.hud.canvas.queue_redraw()
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var saved=root.get_texture().get_image().save_png("/private/tmp/yang-death-guide-long.png")==OK
	var ok=not tips.is_empty() and widest<=820 and saved
	print("DEATH_GUIDE_VISUAL_RESULT tips=",tips.size()," widest=",widest," fits=",ok)
	game.audio.stop_all();game.queue_free();await process_frame;quit(0 if ok else 1)
