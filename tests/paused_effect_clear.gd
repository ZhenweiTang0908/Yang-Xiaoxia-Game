extends SceneTree
func _initialize():call_deferred("run")
func rendered_pixel():
 await process_frame;await RenderingServer.frame_post_draw
 return root.get_texture().get_image().get_pixel(200,180)
func run():
 if DisplayServer.get_name()=="headless":
  push_error("This pixel check requires a rendered window; run without --headless.")
  quit(2);return
 root.size=Vector2i(640,360);root.content_scale_size=root.size
 var bg=ColorRect.new();bg.size=Vector2(root.size);bg.color=Color("18262c");root.add_child(bg)
 var combat=load("res://scripts/combat/combat.gd").new();root.add_child(combat);combat.set_physics_process(false)
 var background=await rendered_pixel();var failed=false
 for action in ["clear","owner"]:
  combat.hazard(Rect2(100,160,200,40),0,1,0,123,"beam");combat.queue_redraw()
  var before=await rendered_pixel()
  if action=="clear":combat.clear()
  else:combat.remove_owner(123)
  var after=await rendered_pixel()
  var ok=before!=background and after==background
  print("PAUSED_EFFECT_CLEAR action=",action," cleared_pixels=",ok)
  failed=failed or not ok
 combat.queue_free();await process_frame;quit(1 if failed else 0)
