extends SceneTree
class Sheet:
 extends "res://scripts/combat/projectile_visual.gd"
 func _draw():
  for i in 5:
   draw_set_transform(Vector2(70+i*125,80),0,Vector2.ONE*3)
   if i==0:draw_blade(Color("f0b086"))
   else:
    var u=float(i)/5
    draw_set_transform(Vector2(70+i*125,80),u*.15,Vector2(1-u*.2,1-u*.65)*3)
    draw_blade(Color(.94,.69,.52,(1-u)*.7))
  draw_set_transform(Vector2.ZERO)
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(640,160);root.content_scale_size=root.size
 var bg=ColorRect.new();bg.size=Vector2(root.size);bg.color=Color("14232c");root.add_child(bg)
 root.add_child(Sheet.new())
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/blade-finish.png");quit()
