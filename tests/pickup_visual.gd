extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.start_new(false);game.set_process(false)
 game.player.set_physics_process(false);game.player.position=Vector2(180,450)
 for e in game.enemies:e.hide();e.set_physics_process(false)
 game.pickups=[]
 for i in 3:game.pickups.append({"x":300+i*80,"y":414,"kind":["bow","heal","spirit"][i],"taken":false})
 game.hint_time=0;game.camera.position=Vector2(350,380);game.camera.zoom=Vector2(2,2)
 await create_timer(.1).timeout;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/pickup-shapes.png")
 game.audio.stop_all();game.queue_free();await process_frame;await create_timer(.1).timeout;quit()
