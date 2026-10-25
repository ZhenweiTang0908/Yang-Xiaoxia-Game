extends SceneTree
func _initialize():call_deferred("run")
func run():
 var bg=ColorRect.new();bg.color=Color("14212a");bg.size=Vector2(960,540);root.add_child(bg)
 for i in 2:
  var label=Label.new();label.text="DEPART / fold in" if i==0 else "ARRIVE / unfold";label.position=Vector2(90+i*470,50);root.add_child(label)
  for j in 3:
   var fx=load("res://scripts/combat/effects.gd").new();fx.position=Vector2(210+i*470,150+j*130);fx.scale=Vector2.ONE*2;root.add_child(fx);fx.set_process(false)
   fx.blink_fold(Vector2.ZERO,i==0,Color("be6765"));fx.folds[0].age=[.025,.10,.19][j];fx.queue_redraw()
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/blink-fold.png");quit()
