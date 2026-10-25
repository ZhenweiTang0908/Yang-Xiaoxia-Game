extends SceneTree
func _initialize():call_deferred("run")
func run():
 var root_view=SubViewport.new();root_view.size=Vector2i(900,210);root_view.render_target_update_mode=SubViewport.UPDATE_ONCE;root.add_child(root_view)
 var background=ColorRect.new();background.color=Color("111522");background.size=Vector2(900,210);root_view.add_child(background)
 for panel in 3:
  var combat=load("res://scripts/combat/combat.gd").new();combat.position=Vector2(panel*300,0);root_view.add_child(combat)
  var left=Rect2(12,25,92,150);var right=Rect2(196,25,92,150)
  if panel==0:
   var a=combat.hazard(left,.5,.25,0,0,"ritual");a.warning_total=.5
   var b=combat.hazard(right,.5,.25,0,0,"ritual");b.warning_total=.5
   combat._physics_process(.25)
  elif panel==1:
   var a=combat.hazard(left,0,.25,0,0,"ritual");a.age=.11
   var b=combat.hazard(right,0,.25,0,0,"ritual");b.age=.11
  else:
   combat.remnants.append({"kind":"ritual","rect":left,"age":.10,"life":.35,"owner":0})
   combat.remnants.append({"kind":"ritual","rect":right,"age":.10,"life":.35,"owner":0})
  combat.queue_redraw()
 await process_frame;await process_frame
 root_view.get_texture().get_image().save_png("res://builds/qa/ritual-lifecycle.png");quit()
