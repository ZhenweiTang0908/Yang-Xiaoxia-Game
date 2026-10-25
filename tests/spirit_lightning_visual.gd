extends SceneTree
func _initialize():call_deferred("run")
func run():
 var view=SubViewport.new();view.size=Vector2i(690,360);view.render_target_update_mode=SubViewport.UPDATE_ONCE;root.add_child(view)
 var bg=ColorRect.new();bg.color=Color("151421");bg.size=Vector2(690,360);view.add_child(bg)
 for panel in 3:
  var combat=load("res://scripts/combat/combat.gd").new();combat.position=Vector2(panel*230,0);view.add_child(combat)
  var rect=Rect2(92,35,46,270)
  if panel==0:
   var h=combat.hazard(rect,.6,.18,0,0,"spirit_lightning");h.warning_total=.6;combat._physics_process(.3)
  elif panel==1:
   var h=combat.hazard(rect,0,.18,0,0,"spirit_lightning");h.age=.07
  else:combat.remnants.append({"kind":"spirit_lightning","rect":rect,"age":.10,"life":.35,"owner":0})
  combat.queue_redraw()
 await process_frame;await process_frame
 view.get_texture().get_image().save_png("res://builds/qa/spirit-lightning-lifecycle.png");quit()
