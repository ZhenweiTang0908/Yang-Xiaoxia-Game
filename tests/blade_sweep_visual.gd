extends SceneTree
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(900,280);root.content_scale_size=Vector2i(900,280)
 var bg=ColorRect.new();bg.color=Color("172932");bg.size=Vector2(900,280);root.add_child(bg)
 var game=load("res://scenes/main.tscn").instantiate();game.qa_mode=true;game.state="paused"
 for i in 3:
  var panel=Node2D.new();panel.position=Vector2(55+i*290,55);root.add_child(panel)
  var label=Label.new();label.text=["预兆 · 刃线定向","释放 · 亮边展开","消散 · 无伤残光"][i];label.position=Vector2(5,-28);panel.add_child(label)
  var combat=load("res://scripts/combat/combat.gd").new();combat.game=game;combat.set_physics_process(false);panel.add_child(combat)
  if i<2:
   var h=combat.hazard(Rect2(5,75,235,55),.4 if i==0 else 0,.2,0,0,"blade_sweep")
   h.warning_total=.6;h.face=1;h.age=.08 if i==1 else 0
  else:combat.remnants.append({"kind":"blade_sweep","rect":Rect2(5,75,235,55),"age":.08,"life":.35,"owner":0})
  combat.queue_redraw()
 await process_frame;await process_frame
 root.get_texture().get_image().save_png("res://builds/qa/blade-sweep-lifecycle.png");quit()
