extends SceneTree
class Samples:
 extends "res://scripts/combat/projectile_visual.gd"
 func _draw():
  var tint=Color("a8dac0")
  for i in 3:
   var at=Vector2(100+i*200,75);draw_set_transform(at,.12,Vector2(3,3));draw_card(tint,1.0,["plain","leaf","loop"][i]);draw_set_transform(Vector2.ZERO)
func _initialize():call_deferred("run")
func run():
 var view=SubViewport.new();view.size=Vector2i(600,160);view.render_target_update_mode=SubViewport.UPDATE_ONCE;root.add_child(view)
 var bg=ColorRect.new();bg.color=Color("151c20");bg.size=Vector2(600,160);view.add_child(bg)
 view.add_child(Samples.new())
 await RenderingServer.frame_post_draw
 view.get_texture().get_image().save_png("res://builds/qa/card-variants.png");quit()
