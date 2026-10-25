extends SceneTree
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(960,540)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true
 game.open_animation_lab()
 await process_frame
 for i in 190:
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://builds/qa/animation/frames/%04d.png"%i)
 game.queue_free();await process_frame;quit()
