extends SceneTree
class Sheet:
 extends "res://scripts/combat/projectile_visual.gd"
 func _draw():
  for i in 4:
   draw_set_transform(Vector2(90+i*150,90),i*PI/2,Vector2.ONE*2)
   draw_wave(Color("f0b086"),1)
   draw_set_transform(Vector2(90+i*150,210),i*PI/2,Vector2.ONE*1.6)
   draw_wave(Color(.94,.69,.52,.35),.5)
  draw_set_transform(Vector2.ZERO)
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(640,280);root.content_scale_size=root.size
 var bg=ColorRect.new();bg.size=Vector2(root.size);bg.color=Color("14232c");root.add_child(bg)
 var sheet=Sheet.new();root.add_child(sheet)
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/qa/wave-directions.png")
 quit()
