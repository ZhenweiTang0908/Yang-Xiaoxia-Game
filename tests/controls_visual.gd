extends SceneTree
func _initialize():call_deferred("run")
func run():
 root.unfocusable=true
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.qa_mode=true
 await process_frame;await process_frame
 game.gamepad.reset_bindings();game.hud.action("controls")
 for family in ["ps","switch","xbox"]:
  game.gamepad.glyphs=family
  game.hud.canvas.queue_redraw()
  await process_frame;await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/private/tmp/yang-controls-"+family+".png")
 game.hud.action("bind_attack")
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/private/tmp/yang-controls-rebinding.png")
 var cancel=InputEventKey.new();cancel.pressed=true;cancel.keycode=KEY_ESCAPE
 game.gamepad.handle(cancel)
 var cancelled=game.gamepad.rebinding.is_empty() and game.state=="controls"
 print("CONTROLS_VISUAL_RESULT cancelled=",cancelled)
 game.queue_free();await process_frame;quit(0 if cancelled else 1)
