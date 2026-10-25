extends SceneTree
var game
func _initialize():call_deferred("run")
func capture(id):
 game.hud.canvas.queue_redraw()
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/interface-"+id+".png")
func run():
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT;root.content_scale_size=Vector2i(960,540);root.size=Vector2i(960,540)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true;game.progress=game.SAVE.defaults();game.developer_mode=false
 await capture("title")
 game.state="settings";await capture("settings")
 game.state="new_confirm";await capture("confirm")
 game.start_new(false);await process_frame
 game.world.visible=true;game.set_process(false);game.set_physics_process(false);game.player.set_physics_process(false)
 for e in game.enemies:e.set_physics_process(false)
 game.player.position=Vector2(480,450);game.camera.position=Vector2(480,270);game.camera.reset_smoothing()
 game.hint="生命已满";game.hint_time=1.5;game.player.dodge_flash=.3
 await capture("combat")
 game.subtitle="断誓枪骑：莫要背对战场。";game.subtitle_time=5;await capture("dialogue")
 for state in ["paused","upgrade","dead","stage_select"]:
  game.state=state;await capture(state)
 game.audio.stop_all();game.queue_free();await process_frame;await process_frame;quit()
