extends SceneTree
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(900,280);root.content_scale_size=Vector2i(900,280)
 var bg=ColorRect.new();bg.color=Color("171d2d");bg.size=Vector2(900,280);root.add_child(bg)
 var game=load("res://scenes/main.tscn").instantiate();game.qa_mode=true;game.state="paused"
 for i in 3:
  var panel=Node2D.new();panel.position=Vector2(55+i*290,55);root.add_child(panel)
  var label=Label.new();label.text=["预兆 · 脚下裂纹","释放 · 裂隙斜斩","消散 · 裂缝闭合"][i];label.position=Vector2(5,-28);panel.add_child(label)
  var combat=load("res://scripts/combat/combat.gd").new();combat.game=game;combat.set_physics_process(false);panel.add_child(combat)
  if i<2:
   var h=combat.hazard(Rect2(75,55,96,96),.4 if i==0 else 0,.18,0,0,"rift")
   h.warning_total=.6;h.age=.07 if i==1 else 0
  else:combat.remnants.append({"kind":"rift","rect":Rect2(75,55,96,96),"age":.10,"life":.35,"owner":0})
  combat.queue_redraw()
 await process_frame;await process_frame
 root.get_texture().get_image().save_png("res://builds/qa/rift-lifecycle.png");quit()
