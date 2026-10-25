extends SceneTree
func _initialize():call_deferred("run")
func run():
 var bg=ColorRect.new();bg.color=Color("14212a");bg.size=Vector2(960,540);root.add_child(bg)
 for i in 3:
  var label=Label.new();label.text=["SOFT / 2 strokes","STONE / 4 sparks","BLOCK / shield glance"][i];label.position=Vector2(60+i*300,70);root.add_child(label)
  for j in 3:
   var fx=load("res://scripts/combat/effects.gd").new();fx.position=Vector2(130+i*300,160+j*120);fx.scale=Vector2.ONE*3;root.add_child(fx);fx.set_process(false)
   fx.melee_contact(Vector2.ZERO,["soft","stone","block"][i],1)
   fx.melee_contacts[0].age=[.02,.08,.15][j];fx.queue_redraw()
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/melee-contact.png");quit()
