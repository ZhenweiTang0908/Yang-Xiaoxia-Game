extends SceneTree
func _initialize():call_deferred("run")
func run():
 var view=SubViewport.new();view.size=Vector2i(900,210);view.render_target_update_mode=SubViewport.UPDATE_ONCE;root.add_child(view)
 var bg=ColorRect.new();bg.color=Color("151c20");bg.size=Vector2(900,210);view.add_child(bg)
 for panel in 3:
  var combat=load("res://scripts/combat/combat.gd").new();combat.position=Vector2(panel*300,0);view.add_child(combat)
  if panel==0:
   var h=combat.hazard(Rect2(95,120,60,42),.8,.25,0,0,"binding_rune");h.warning_total=.8;combat._physics_process(.4)
   var p=combat.hazard(Rect2(190,126,50,36),.32,.2,0,0,"pounce_impact");p.warning_total=.32;combat._physics_process(.12)
  elif panel==1:
   var h=combat.hazard(Rect2(95,120,60,42),0,.25,0,0,"binding_rune");h.age=.1
   var p=combat.hazard(Rect2(190,126,50,36),0,.2,0,0,"pounce_impact");p.age=.08
  else:
   combat.remnants.append({"kind":"binding_rune","rect":Rect2(95,120,60,42),"age":.1,"life":.35,"owner":0})
   combat.remnants.append({"kind":"pounce_impact","rect":Rect2(190,126,50,36),"age":.1,"life":.35,"owner":0})
  combat.queue_redraw()
 await process_frame;await process_frame
 view.get_texture().get_image().save_png("res://builds/qa/enemy-skill-lifecycle.png");quit()
