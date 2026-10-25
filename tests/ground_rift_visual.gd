extends SceneTree
func _initialize():call_deferred("run")
func run():
 var view=SubViewport.new();view.size=Vector2i(750,190);view.render_target_update_mode=SubViewport.UPDATE_ONCE;root.add_child(view)
 var bg=ColorRect.new();bg.color=Color("171522");bg.size=Vector2(750,190);view.add_child(bg)
 for panel in 3:
  var combat=load("res://scripts/combat/combat.gd").new();combat.position=Vector2(panel*250,0);view.add_child(combat)
  var rect=Rect2(25,105,200,34)
  if panel==0:
   var h=combat.hazard(rect,.5,1.1,0,0,"ground_rift");h.warning_total=.5;combat._physics_process(.25)
  elif panel==1:
   var h=combat.hazard(rect,0,1.1,0,0,"ground_rift");h.age=.22
  else:combat.remnants.append({"kind":"ground_rift","rect":rect,"age":.11,"life":.35,"owner":0})
  combat.queue_redraw()
 await process_frame;await process_frame
 view.get_texture().get_image().save_png("res://builds/qa/ground-rift-lifecycle.png");quit()
