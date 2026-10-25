extends SceneTree
func _initialize():call_deferred("run")
func run():
 var view=SubViewport.new();view.size=Vector2i(900,190);view.render_target_update_mode=SubViewport.UPDATE_ONCE;root.add_child(view)
 var bg=ColorRect.new();bg.color=Color("151421");bg.size=Vector2(900,190);view.add_child(bg)
 for panel in 3:
  var combat=load("res://scripts/combat/combat.gd").new();combat.position=Vector2(panel*300,0);view.add_child(combat)
  var rect=Rect2(15,65,270,60)
  if panel==0:
   var h=combat.hazard(rect,.6,.85,0,0,"spirit_beam");h.warning_total=.6;h.face=1;combat._physics_process(.3)
  elif panel==1:
   var h=combat.hazard(rect,0,.85,0,0,"spirit_beam");h.face=1;h.age=.18;h.duration=.67
  else:combat.remnants.append({"kind":"spirit_beam","rect":rect,"age":.10,"life":.35,"owner":0})
  combat.queue_redraw()
 await process_frame;await process_frame
 view.get_texture().get_image().save_png("res://builds/qa/spirit-beam-lifecycle.png");quit()
